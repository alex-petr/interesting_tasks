class CopyImageWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :image_parser

  def perform(donor_product_image_id)
    donor_product_image = DonorProductImage.includes(:donor_product => :products).where(id: donor_product_image_id).first

    donor_product_image.donor_product.products.each do |product|
      begin
        product.product_images.create(image: donor_product_image.url)
      rescue
        puts "can't create"
      end
    end
  end
end
