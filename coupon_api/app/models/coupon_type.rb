# == Schema Information
#
# Table name: coupon_types
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CouponType < ActiveRecord::Base
  has_many :coupon_coupon_types
  has_many :coupons, through: :coupon_coupon_types, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
