# == Schema Information
#
# Table name: coupons
#
#  id                      :integer          not null, primary key
#  brand_id                :integer
#  seller_id               :integer
#  name                    :string
#  code                    :string
#  discount                :integer
#  description             :string
#  approved                :boolean          default(FALSE), not null
#  expires_at              :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  moderated               :boolean          default(FALSE), not null
#  url                     :text
#  uses_count              :integer          default(0), not null
#  home_page               :boolean          default(FALSE), not null
#  coupon_page             :boolean          default(FALSE), not null
#  donor_id                :integer
#  default_logo            :boolean          default(FALSE), not null
#  coupon_discount_type_id :integer
#  promotional             :boolean          default(TRUE), not null
#  coupon_image_id         :integer
#
# Indexes
#
#  index_coupons_on_coupon_image_id  (coupon_image_id)
#

FactoryGirl.define do
  factory :coupon do
    brand
    seller
    coupon_discount_type
    name { FFaker::Product.brand }
    code { FFaker::Vehicle.vin }
    discount 50
    description { FFaker::Lorem.paragraph }
    expires_at { Time.zone.now }
  end

  factory :test_coupon, class: Coupon do
    brand_id 28
    seller_id 25
    name 'Brance'
    code '11TFQ32388Y248502'
    discount 50
    description 'Ea ratione voluptates dolores voluptas. Voluptatem et minus non quae magni aspernatur. Harum magni ullam minima quia ipsum. Quia aut rem animi labore et amet voluptatem et.'
    expires_at { Time.zone.now }
    url 'http://rubyonrails.org/'
    coupon_discount_type_id 65
  end

end
