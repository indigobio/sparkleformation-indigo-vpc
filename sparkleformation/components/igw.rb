SparkleFormation.build do
  dynamic!(:ec2_internet_gateway, :default)

  dynamic!(:ec2_vpc_gateway_attachment, :default).properties do
    internet_gateway_id ref!(:default_ec2_internet_gateway)
    vpc_id ref!(:vpc)
  end

  dynamic!(:ec2_route_table, :default).properties do
    vpc_id ref!(:vpc)
  end

  dynamic!(:ec2_route, :default) do
    depends_on 'DefaultEc2VpcGatewayAttachment'
    properties do
      destination_cidr_block '0.0.0.0/0'
      gateway_id ref!(:default_ec2_internet_gateway)
      route_table_id ref!(:default_ec2_route_table)
    end
  end
end