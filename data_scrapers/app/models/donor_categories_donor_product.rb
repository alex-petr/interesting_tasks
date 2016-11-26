# == Schema Information
#
# Table name: donor_categories_donor_products
#
#  id                :integer          not null, primary key
#  donor_product_id  :integer
#  donor_category_id :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_donor_categories_donor_products_on_donor_category_id  (donor_category_id)
#  index_donor_categories_donor_products_on_donor_product_id   (donor_product_id)
#

class DonorCategoriesDonorProduct < ActiveRecord::Base
  belongs_to :donor_product
  belongs_to :donor_category
  has_many :category_donor_categories

  validates :donor_product_id, uniqueness: {scope: :donor_category_id}
end
