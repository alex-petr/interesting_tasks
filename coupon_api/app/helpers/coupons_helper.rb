module CouponsHelper
  def coupon_types
    @coupon_types = CouponType.all
  end

  # Get coupon logo asset path depending on the default logo/brand logo/donor logo conditions.
  # @param [Coupon] coupon
  def coupon_logo(coupon)
    url = "coupons/default-#{request_host}.png"

    unless coupon.default_logo
      if coupon.coupon_image.present?
        url = coupon.coupon_image.image(:medium)
      elsif coupon.brand.present? && coupon.brand.logo.exists?
        url = coupon.brand.logo(:medium)
      elsif coupon.donor.present? && coupon.donor.logo.exists?
        url = coupon.donor.logo(:large)
      end
    end

    image_url(url)
  end
end
