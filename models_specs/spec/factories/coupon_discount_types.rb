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

FactoryGirl.define do
  factory :coupon_discount_type do
    name { FFaker::Product.brand }
    key  { FFaker::Product.brand.parameterize }
  end

  factory :test_coupon_discount_type, class: CouponDiscountType do
    name { 'Amount' }
    key  { 'amount'}
  end
end
