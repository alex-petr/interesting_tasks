# == Schema Information
#
# Table name: category_donor_categories
#
#  id                :integer          not null, primary key
#  category_id       :integer
#  donor_category_id :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class CategoryDonorCategory < ActiveRecord::Base
  belongs_to :category
  belongs_to :donor_category

  validates :donor_category_id, uniqueness: { scope: :category_id }
end
