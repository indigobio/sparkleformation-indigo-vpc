SparkleFormation.dynamic(:hosted_zone) do |options = {}|

  parameters(:hosted_zone_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default options.fetch(:zone_name, ENV['private_domain'])
    description options.fetch(:description, 'A hosted route53 zone')
    constraint_description 'can only contain ASCII characters'
  end

  dynamic!(:route53_hosted_zone, 'whatever').properties do
    name ref!(:hosted_zone_name)
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