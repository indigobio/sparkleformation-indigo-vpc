SparkleFormation.dynamic(:launch_config) do |name, options = {}|

  parameters("#{name}_instance_type".gsub('-', '_').to_sym) do
    type 'String'
    allowed_values ['t2.small', 't2.medium', 'm3.large', 'c4.large']
    default options[:instance_type] || 't2.small'
  end

  dynamic!(:auto_scaling_launch_configuration, name).properties do
    image_id map!(:region_to_nat_ami, region!, :ami)
    instance_type ref!("#{name}_instance_type".gsub('-', '_').to_sym)
    associate_public_ip_address 'true'
    iam_instance_profile ref!(:nat_instance_iam_profile)
    key_name ref!(:ssh_key_pair)
    security_groups array!(
      *options[:security_groups].map { |sg| ref!(sg) }
    )
    user_data registry!(:nat_user_data)
  end
end
