SparkleFormation.new(:vpc, :provider => :aws).load(:base, :igw, :ssh_key_pair, :nat_ami, :nat_instance_iam).overrides do
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

  dynamic!(:vpc_security_group, 'nat',
           :ingress_rules => [
             { :cidr_ip => ref!(:allow_ssh_from), :ip_protocol => 'tcp', :from_port => '22', :to_port => '22' }
           ],
           :allow_icmp => false
  )

  dynamic!(:vpc_security_group, 'private', :ingress_rules => [])

  dynamic!(:security_group_ingress, 'nat-to-private-all', :source_sg => attr!(:nat_ec2_security_group, 'GroupId'), :ip_protocol => '-1', :from_port => '-1', :to_port => '-1', :target_sg => attr!(:private_ec2_security_group, 'GroupId'))
  dynamic!(:security_group_ingress, 'private-to-nat-all', :source_sg => attr!(:private_ec2_security_group, 'GroupId'), :ip_protocol => '-1', :from_port => '-1', :to_port => '-1', :target_sg => attr!(:nat_ec2_security_group, 'GroupId'))

  dynamic!(:launch_config, 'nat_instances', :public_ips => true, :instance_id => :nat_instance, :security_groups => [:nat_ec2_security_group])
  dynamic!(:auto_scaling_group, 'nat_instances', :launch_config => :nat_instances_auto_scaling_launch_configuration, :subnets => public_subnets )
end
