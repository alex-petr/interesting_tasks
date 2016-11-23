class Api::V1::CouponSerializer < ActiveModel::Serializer

  attributes :id, :name, :code, :discount, :discount_type, :description, :approved, :expires_at, :url, :uses_count, :image_url,
             :home_page, :coupon_page, :translations

  has_many :coupon_types
  has_one :brand, :seller, :donor

  def discount_type
    object.coupon_discount_type_id
  end

  def expires_at
    object.expires_at.strftime('%m/%d/%Y %H:%M')
  end

  def image_url
    ApplicationController.helpers.coupon_logo(object)
  end

  def translations
    {
      ends: ApplicationController.helpers.t('coupons.ends').mb_chars.capitalize,
      uses: ApplicationController.helpers.t('coupons.uses').mb_chars.capitalize,
      currency: ApplicationController.helpers.t('number.currency.format.unit')
    }
  end

end
