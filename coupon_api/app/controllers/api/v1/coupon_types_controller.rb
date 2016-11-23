class Api::V1::CouponTypesController < ApplicationController

  respond_to :json

  def index
    # params[:page] ||= 1
    # per_page = 10

    @coupon_types = CouponType.order(:created_at)#.page(params[:page]).per(per_page)

    render json: @coupon_types, root: false
  end

end
