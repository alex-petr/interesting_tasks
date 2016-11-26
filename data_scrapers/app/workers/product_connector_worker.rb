
class ProductConnectorWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :match_products_parser

  def perform(donor_product_id)

    ProductConnector.new.connect_donor_product(donor_product_id)
  end
end
