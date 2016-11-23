class ProductLinkWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :parse_product_list_parser

  def perform(donor_id, donor_category_id, link)
    donor_category = DonorCategory.find(donor_category_id)
    donor_product = DonorProduct.find_by_donor_id_and_path(donor_id, link)
    if donor_product.nil?
      donor_product = DonorProduct.new(path: link.squish, donor_id: donor_id)
      message = "#{donor_product.save ? '' : 'NOT '}saved: donor=#{donor_id} #{link} "
    else
      message = "already exists: #{donor_product.id} #{link} "
    end
    # puts "product link #{message} "
    # donor_category.donor_products << donor_product if donor_product.valid? && donor_category.joins("LEFT JOIN donor_categories_donor_products ON donor_categories_donor_products.category_id = donor_categories.id").where("donor_categories_donor_products.donor_product_id = ?", donor_product.id).count == 0
    donor_category.donor_products << donor_product if donor_product.valid? && DonorCategory.joins("LEFT JOIN donor_categories_donor_products ON donor_categories_donor_products.donor_category_id = donor_categories.id").where("donor_categories.id = ? AND donor_categories_donor_products.donor_product_id = ?", donor_category.id, donor_product.id).count == 0
  end
end