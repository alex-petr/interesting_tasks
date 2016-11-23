class DonorProductUpdateWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :update_product_details

  def perform(donor_product_id, params)

    # make description empty if nil? - prevent "stack level too deep
    params["description"] = '' if params["description"].nil?

    donor_product = DonorProduct.find(donor_product_id)

    # general_logger = ActiveSupport::Logger.new("#{Rails.root}/log/scrappers/general.log")

    Chewy.strategy(:sidekiq) do
      if donor_product.update(params)
        product = donor_product.products.first
        unless product.nil?
          product.description = donor_product.description
          product.save
        end
        # general_logger.info("#{Time.zone.now} donor product successfully updated (worker: DonorProductUpdateWorker): id: #{donor_product.id}; url: #{donor_product.url};")
      else
        # general_logger.warn("#{Time.zone.now} donor product FAILED updating (worker: DonorProductUpdateWorker): id: #{donor_product.id}; url: #{donor_product.url}; errors: #{donor_product.errors.inspect}")
      end
    end

  end

end
