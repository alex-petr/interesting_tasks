# == Schema Information
#
# Table name: donor_products_specification_values
#
#  id                     :integer          not null, primary key
#  donor_product_id       :integer
#  specification_value_id :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class DonorProductsSpecificationValue < ActiveRecord::Base
  belongs_to :specification_value
  belongs_to :donor_product

  validates :specification_value_id, uniqueness: {scope: :donor_product_id}
end
