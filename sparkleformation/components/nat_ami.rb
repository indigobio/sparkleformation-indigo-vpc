SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'.disable_camel!,    :ami => 'ami-b73b63a0') # amzn-ami-hvm-2016.09.0.x86_64-ebs (NOT the nat ami)
    set!('us-east-2'.disable_camel!,    :ami => 'ami-58277d3d')
    set!('us-west-1'.disable_camel!,    :ami => 'ami-23e8a343')
    set!('us-west-2'.disable_camel!,    :ami => 'ami-5ec1673e')
  end
end
