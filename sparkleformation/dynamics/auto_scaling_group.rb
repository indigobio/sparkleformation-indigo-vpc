SparkleFormation.dynamic(:auto_scaling_group) do |name, options = {}|

  dynamic!(:auto_scaling_auto_scaling_group, name).properties do
    availability_zones registry!(:zones)
    min_size 0
    desired_capacity 1
    max_size 1
    data!['VPCZoneIdentifier'] = registry!(:public_subnets_ref_list)
    launch_configuration_name ref!(options[:launch_config])
    tags _array(
           -> {
             key 'Name'
             value "#{name}_asg_instance".to_sym
             propagate_at_launch 'true'
           },
           -> {
             key 'Environment'
             value ENV['environment']
             propagate_at_launch 'true'
           }
         )
  end
end