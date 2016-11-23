# == Schema Information
#
# Table name: coupon_coupon_types
#
#  id             :integer          not null, primary key
#  coupon_id      :integer
#  coupon_type_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_coupon_coupon_types_on_coupon_id       (coupon_id)
#  index_coupon_coupon_types_on_coupon_type_id  (coupon_type_id)
#

class CouponCouponType < ActiveRecord::Base
  belongs_to :coupon
  belongs_to :coupon_type

  validates :coupon_id, uniqueness: { scope: :coupon_type_id }
end
