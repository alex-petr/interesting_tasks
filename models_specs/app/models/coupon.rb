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

class Coupon < ActiveRecord::Base
  has_many :coupon_coupon_types
  has_many :coupon_types, through: :coupon_coupon_types, dependent: :destroy

  belongs_to :brand, -> { unscope(where: :custom) }
  belongs_to :donor, -> { unscope(where: :custom) }
  belongs_to :seller, -> { unscope(where: :custom) }
  belongs_to :coupon_discount_type
  belongs_to :coupon_image

  validates :name, :discount, :description, :expires_at, :coupon_discount_type_id, presence: true
  validates :discount, :uses_count, numericality: { only_integer: true }
  validates_uniqueness_of :code, scope: [:brand_id, :name, :url]
end
