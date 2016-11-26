class DonorProductCreateWorker
  require 'support/category_logger'

  include Sidekiq::Worker
  sidekiq_options :queue => :parse_pages_parser

  def perform(donor_category_id, donor_product_data)
    donor_category = DonorCategory.find(donor_category_id)

    category_logger = ParserSupport::CategoryLogger.new(donor_category)

    donor_product = DonorProduct.new(donor_product_data)

    if donor_product.save
      category_logger.saved_donor_products_log.info("#{Time.zone.now} donor product created (worker: DonorProductCreateWorker): id: #{donor_product.id}; url: #{donor_product.url}")
      donor_category.donor_products << donor_product
    else
      error_msg = ""
      donor_product.errors.each{|attr,err| error_msg += "#{attr.to_s} - #{err};" }
      category_logger.failed_donor_products_log.warn("#{Time.zone.now} donor product failed creation (worker: DonorProductCreateWorker): url: #{donor_product_data['path']}; errors: #{error_msg}")
    end


  end

end
