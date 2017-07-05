SparkleFormation.dynamic(:hosted_zone) do |name, options = {}|

  parameters("#{name}_hosted_zone_name".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default options.fetch(:zone_name, ENV['private_domain'])
    description options.fetch(:description, 'A hosted route53 zone')
    constraint_description 'can only contain ASCII characters'
  end

  dynamic!(:route53_hosted_zone, name.gsub(/[.-]/, '_').to_sym).properties do
    name ref!("#{name}_hosted_zone_name".to_sym)
    if options.has_key?(:vpcs)
      data![:VPCs] = _array(
        *options[:vpcs].map { |vpc| -> {
          data![:VPCId] = vpc[:id]
          data![:VPCRegion] = vpc[:region]
        }}
      )
    end
  end
end
