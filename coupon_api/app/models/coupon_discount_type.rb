# == Schema Information
#
# Table name: coupon_discount_types
#
#  id         :integer          not null, primary key
#  name       :string
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CouponDiscountType < ActiveRecord::Base
  has_one :coupon

  validates :name, :key, presence: true, uniqueness: true
end
