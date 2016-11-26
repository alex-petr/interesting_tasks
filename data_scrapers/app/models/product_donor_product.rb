# == Schema Information
#
# Table name: product_donor_products
#
#  id               :integer          not null, primary key
#  product_id       :integer
#  donor_product_id :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_product_donor_products_on_donor_product_id  (donor_product_id)
#  index_product_donor_products_on_product_id        (product_id)
#

class ProductDonorProduct < ActiveRecord::Base
  belongs_to :product
  belongs_to :donor_product, :dependent => :destroy

  validates :donor_product_id, uniqueness: {scope: :product_id}
  validate :unique_donor

  counter_culture :product, column_name: "donor_products_count"

  after_create :update_price_and_discount
  after_destroy :update_price_and_discount

  delegate :update_price_and_discount, to: :product, allow_nil: true
  # delegate :update_max_discount, to: :product, allow_nil: true


  def unique_donor
    pdps = ProductDonorProduct.where(product_id: self.product_id).includes(:donor_product)
    pdps = pdps.where.not(id: self.id) unless self.id.nil?

    donor_ids = pdps.collect{|i| i.donor_product.donor_id unless i.donor_product.nil?}

    dp = DonorProduct.find_by(id: self.donor_product_id)
    if !dp.nil? && donor_ids.include?(dp.donor_id)
      errors.add(:donor_product_id, "Duplicate Donor for product")
    end
  end

end
