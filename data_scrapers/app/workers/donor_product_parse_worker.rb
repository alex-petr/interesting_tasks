class DonorProductParseWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :update_product_details

  # fetch data from donor_product page and update donor product (description, specification, gallery)
  def perform(donor_product_id)
    donor_product = DonorProduct.find(donor_product_id)

    parser_instance = "#{donor_product.donor.parser_class}".constantize.new()

    parser_instance.parse_product(donor_product) if parser_instance.respond_to?(:parse_product, true)
  end

end
