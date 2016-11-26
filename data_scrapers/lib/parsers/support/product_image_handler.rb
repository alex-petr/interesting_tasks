module ParserSupport
  module ProductImageHandler
    def copy_images_from_donor_product_to_product(donor_product_id, product_id)
      donor_product_images = DonorProductImage.where(donor_product_id: donor_product_id)

      donor_product_images.each do |dpi|
        product_image = ProductImage.create(product_id: product_id)

        begin
          img_encoded_url = URI.encode(dpi.url)
          img_url = URI.parse(img_encoded_url)
          product_image.image = img_url.to_s.sub(/^\/\//, '')
          product_image.save
        rescue Exception => e
          # TODO Add rollbar informer
          puts "ProductImageHandler errors: #{e.inspect}"
          next
        end

      end
    end
  end
end
