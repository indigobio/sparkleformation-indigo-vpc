## sparkleformation-indigo-vpc
This repository contains a SparkleFormation template that creates a VPC, or 
private network, on Amazon Web Services.

SparkleFormation is a tool that creates CloudFormation templates, which are
static documents declaring resources for AWS to create.

The network, spanning a /16 CIDR allocation in the 172.16.0.0/12 IP address
range, consists of a public and private subnet for every availability zone
that we have access to in any given AWS region.  

Additionally, the template creates an internal Route53 (DNS) zone.

Finally, the template will create a NAT instance.  On successful boot, the 
NAT instance will identify each private subnet by its `Network` tag and
update the VPC's routing tables, adding a default route through its network
interface.  The NAT instance needs an IAM instance profile allowing it to 
lookup and modify EC2 routes.

### Dependencies

The template requires three external Sparkle Pack gems, which are noted in
the Gemfile and the .sfn file.  These gems interact with AWS through the
`aws-sdk-core` gem to identify or create  availability zones, subnets, and 
security groups.

### Parameters

When launching the compiled CloudFormation template, you will be prompted for
some stack parameters:

| Parameter | Default Value | Purpose |
|-----------|---------------|---------|
| AllowSshFrom | 127.0.0.1/32 | Governs SSH access to the NAT instance.  Setting to 127.0.0.1/32 effectively disables SSH accesss. |
| CidrPrefix | 16 | The CIDR prefix will be the second octet of the VPC's addrange range.  e.g. 172.16.0.0/16 |
| EnableDnsHostnames | true | Just leave it set to true |
| EnableDnsSupport | true | Just leave it set to true |
| HostedZoneName | variable | `ENV['environment']`.`ENV['organization']` e.g. dev.indigo | 
| InstanceTenancy | default | Just leave it set to default |
| NatInstancesInstanceType | t2.small | Larger instances have more network capacity.  Valid values are t2.small, t2.medium, m3.large, and c4.large |
| SshKeyPair | indigo-bootstrap | An SSH key pair for use when logging into the NAT instance.  Log in as the 'ec2-user' account. |
| VpcName	| variable | `ENV['organization']`-`ENV['environment']`-`ENV['AWS_REGION']`-vpc |

