# == Schema Information
#
# Table name: category_brands
#
#  id          :integer          not null, primary key
#  category_id :integer
#  brand_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CategoryBrand < ActiveRecord::Base
  belongs_to :category
  belongs_to :brand

  validates :brand_id, uniqueness: {scope: :category_id}

  after_commit :touch_category # Update `category.updated_at` after every create/update/destroy.

  def touch_category
    self.category.touch
  end
end
