require 'support/donor_product_image_handler'
class DonorProductImageCreateWorker
  include Sidekiq::Worker
  include ParserSupport::DonorProductImageHandler
  sidekiq_options :queue => :image_parser

  def perform(donor_product_id, url)
    # DonorProductImage.create(url: url, dhash: Dhash.calculate(url), donor_product_id: donor_product_id)
    save_image(donor_product_id, url)
  end

end
