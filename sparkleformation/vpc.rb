#SparkleFormation.new(:vpc, :provider => :aws).load(:base, :igw, :ssh_key_pair, :nat_ami, :nat_instance_iam).overrides do
SparkleFormation.new(:vpc, :provider => :aws).load(:base, :igw) do
  description <<EOF
VPC, including a NAT instance, NAT and private subnet security groups, and an internal hosted DNS zone.
EOF

  ENV['vpc_name'] ||= "#{ENV['org']}-#{ENV['environment']}-#{ENV['AWS_REGION']}-vpc"

  dynamic!(:vpc, ENV['vpc_name'])

  dynamic!(:public_subnets)

  dynamic!(:private_subnets)

  dynamic!(:hosted_zone, 'private', :zone_name => ENV['private_domain'], :vpcs => [{ :id => ref!(:vpc), :region => region! }])

  dynamic!(:hosted_zone, 'k8s', :zone_name => "k8s.#{ENV['public_domain']}")

  dynamic!(:vpc_security_group, 'private', :ingress_rules => [])
end
