class HomeController < ApplicationController
  caches_page :index, expires_in: 1.hour

  def index
    @banners               = Banner.where(display: true).limit(1)
    @coupons               = Coupon.includes(:coupon_types, :brand, :seller).order('coupons.created_at DESC').limit(8)
    @brands                = Brand.where(home_page: true)
    @title                 = Partial.where(key: 'homepage.title').pluck(:template).first
    @description           = Partial.where(key: 'homepage.description').pluck(:template).first
    @seo_footer            = Partial.where(key: 'homepage.seo_footer').pluck(:template).first
    @blog_posts_cache_name = 'blog_posts'
    @blog_posts_limit      = 6
  end
end
