#!/bin/bash -e

run_if_yes () {
  cmd=$1
  echo -n "$cmd [Y/n]? "
  read response
  case $response in
    Y|y)
      eval $cmd
    ;;
    *)
     echo "skipping"
    ;;
  esac
}

del_stack () {
  stack=$1
  run_if_yes "aws cloudformation delete-stack --stack-name $stack"
  echo -n "Waiting for resource deletion"
  while [ "$(aws cloudformation describe-stacks --stack-name $stack --query 'Stacks[].StackStatus' --output text)" == "DELETE_IN_PROGRESS" ]; do
    echo -n .
    sleep 1
  done
  if [ "$(aws cloudformation describe-stacks --stack-name $stack --query 'Stacks[].StackStatus' --output text)" == "DELETE_FAILED" ]; then
    echo "$stack failed to delete"
    exit 1
  fi
}

# Tear down route53 records that exist in $private_domain and $public_domain
# Basically, you have to send a change batch file, in JSON, to the route53
# API with the full record set and a DELETE action, so we construct each
# change batch document on the fly.
zap_records () {
  domain=$1
  zone=$(aws route53 list-hosted-zones --query 'HostedZones[?Name == `'$domain'.`].Id' --output text)
  zone=${zone##*/}
  if [ ! -z $zone ]; then
    while [ $(aws route53 list-resource-record-sets --hosted-zone-id $zone --query 'ResourceRecordSets[?Name != `'$domain'.`] | length(@)') -gt 0 ]; do
      cat > delete.json <<EOF
{
  "Comment": "delete record",
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet":
EOF
    aws route53 list-resource-record-sets --hosted-zone-id $zone --query 'ResourceRecordSets[?Name != `'$domain'.`] | {ResourceRecordSet: [0]} | ResourceRecordSet' | sed -e 's/^/      /' >> delete.json

  cat >> delete.json <<EOF
    }
  ]
}
EOF

      run_if_yes "aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://delete.json"
      if [ -f delete.json ]; then 
        rm delete.json
      fi
    done
  fi
}

vpc=$(aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=$environment" --query 'Vpcs[].VpcId' --output text)
if [ -z "$vpc" ]; then
  echo "No vpc found."
  exit
fi

# Tear down any EC2 instances that may have been spun up by hand,
# or detached from auto scaling groups to troubleshoot.
for orphan in $(aws ec2 describe-instances --filter "Name=vpc-id,Values=$vpc" --query 'Reservations[].Instances[].InstanceId' --output text); do
  run_if_yes "aws ec2 terminate-instances --instance-ids $orphan"
  echo -n "waiting for $orphan to terminate"
  while [ $(aws ec2 describe-instances --instance-ids $orphan --query 'Reservations[].Instances[].State.Name' --output text) != "terminated" ] ; do 
    echo -n .
    sleep 1
  done
  echo
done
echo

# Tear down Elastic Network Interfaces which get left behind by lambdas.
for attachment in $(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpc" --query 'NetworkInterfaces[?Status == `in-use` && contains(Description, `NAT Gateway`) == `false`].Attachment.AttachmentId' --output text); do
  run_if_yes "aws ec2 detach-network-interface --attachment-id $attachment"
done

for eni in $(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpc" --query 'NetworkInterfaces[?contains(Description, `NAT Gateway`) == `false`].NetworkInterfaceId' --output text); do
  run_if_yes "aws ec2 delete-network-interface --network-interface-id $eni"
done

zap_records $public_domain
zap_records k8s.$public_domain
zap_records $private_domain

# Tear down the stack
stack=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE DELETE_FAILED \
  --query 'StackSummaries[].StackId' --output table | grep ${environment}-vpc-${AWS_DEFAULT_REGION} \
  | awk '{print $2}')

if [ -n "$stack" ]; then
  del_stack $stack
else
  echo "No stack found."
fi
