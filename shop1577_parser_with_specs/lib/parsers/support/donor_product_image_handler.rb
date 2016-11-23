require 'support/image_handler'
module ParserSupport
  module DonorProductImageHandler
    include ParserSupport::ImageHandler

    DRY_RUN = Rails.env.development?

    # Save image gallery to donor product
    # Params:
    # +donor_product_id+ is id of donor_product
    # +gallery_nodes+ is set of nodes of gallery
    # +image_src_attribute+ - attribute which is used to get image_path from image node element (:src by default)
    #
    def save_gallery(donor_product_id, gallery_nodes, image_src_attribute = :src)
      return false if gallery_nodes.blank?

      gallery_nodes.each{|img_node| save_image(donor_product_id, img_node[image_src_attribute]) unless img_node.try(:[], image_src_attribute).nil? }
    end

    def save_image(donor_product_id, img_url)
      image_url = update_image_url(img_url)

      return false unless remote_file_exists?(image_url)

      # dhash = image_dhash(image_url)

      # return false if dhash.nil?

      puts "before DonorProductImage.create!!!!"
      puts image_url
      DonorProductImage.create(url: image_url, donor_product_id: donor_product_id) unless DRY_RUN
    end

  end
end
