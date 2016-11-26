require 'support/donor_product_handler'
class DonorProductPingWorker
  include Sidekiq::Worker
  include ParserSupport::DonorProductHandler
  # sidekiq_options :queue => :update_prices_parser

  def perform(donor_product_id)
    donor_product = DonorProduct.includes(:donor).where(id: donor_product_id).first

    parser_instance = "#{donor_product.donor.parser_class}".constantize.new()
    parser_instance.check_donor_product_status(donor_product) if parser_instance.respond_to?(:check_donor_product_status)
  end

end
