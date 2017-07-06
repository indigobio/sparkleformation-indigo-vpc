#SparkleFormation.new(:vpc, :provider => :aws).load(:base, :igw, :ssh_key_pair, :nat_ami, :nat_instance_iam).overrides do
SparkleFormation.new(:vpc, :provider => :aws).load(:base, :igw, :ssh_key_pair).overrides do
  description <<EOF
VPC, including a NAT instance, NAT and private subnet security groups, and an internal hosted DNS zone.
EOF

  ENV['vpc_name'] ||= "#{ENV['org']}-#{ENV['environment']}-#{ENV['AWS_REGION']}-vpc"

  parameters(:allow_ssh_from) do
    type 'String'
    allowed_pattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    default '127.0.0.1/32'
    description 'Network to allow SSH from, to NAT instances. Note that the default of 127.0.0.1/32 effectively disables SSH access.'
    constraint_description 'Must follow IP/mask notation (e.g. 192.168.1.0/24)'
  end

  dynamic!(:vpc, ENV['vpc_name'])

  dynamic!(:public_subnets)

  dynamic!(:private_subnets)

  dynamic!(:hosted_zone, 'private', :zone_name => ENV['private_domain'], :vpcs => [{ :id => ref!(:vpc), :region => region! }])

  dynamic!(:hosted_zone, 'k8s', :zone_name => "k8s.#{ENV['public_domain']}")

  dynamic!(:vpc_security_group, 'private', :ingress_rules => [])
end
