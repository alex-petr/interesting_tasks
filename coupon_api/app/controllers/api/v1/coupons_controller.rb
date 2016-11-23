class Api::V1::CouponsController < ApplicationController

  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token

  respond_to :json

  ERROR_MESSAGE_INCLUDE_PARAM = 'Please include `%{param}` parameter in request'
  ERROR_MESSAGE_NOT_FOUND     = 'Couldn\'t find coupon with `id`=`%{param}`'
  ERROR_MESSAGE_CANT_VERIFY   = 'Can\'t verify CSRF token authenticity'

  RECORDS_PER_PAGE = 10

  def initialize
    @response = {
      data: { errors: { message: ERROR_MESSAGE_INCLUDE_PARAM } },
      status: :unprocessable_entity # :bad_request
    }
  end

  def index
    @response[:data]   = Coupon.order(:created_at).page(params[:page] || 1).per(RECORDS_PER_PAGE)
    @response[:status] = @response[:data].empty? ? :not_found : :ok
    render_response
  end

  def show
    begin
      coupon = Coupon.find(params[:id])

      response = coupon.as_json
      response[:coupon_path] = Rails.application.routes.url_helpers.coupon_brand_path(brand_url: coupon.brand.path, id: coupon.id)
      @response = { data: response, status: :ok }
    rescue ActiveRecord::RecordNotFound
      @response[:data][:errors][:message] = ERROR_MESSAGE_NOT_FOUND
      create_response_error(params[:id])
      @response[:status] = :not_found
    end
    render_response
  end

  def create
    if !params[:coupon]
      create_response_error(:coupon)
    elsif !params[:coupon][:coupon_types]
      create_response_error('coupon[coupon_types]')
    else
      coupon = Coupon.new(coupon_params)
      coupon.coupon_types << CouponType.where(id: params[:coupon][:coupon_types])
      if coupon.save
        @response = { data: coupon, status: :created }
      else
        @response[:data][:errors] = coupon.errors
      end
    end
    render_response
  end

  def update
    if !params[:coupon]
      create_response_error(:coupon)
    else
      begin
        coupon = Coupon.find(params[:id])

        # We can only increment `uses_count` field, but not assign some value to it.
        coupon.increment(:uses_count) if params[:coupon][:uses_count]

        if coupon.update(coupon_params)
          @response = { data: coupon, status: :ok }
        else
          @response[:data][:errors] = coupon.errors
        end
      rescue ActiveRecord::RecordNotFound
        @response[:data][:errors][:message] = ERROR_MESSAGE_NOT_FOUND
        create_response_error(params[:id])
        @response[:status] = :not_found
      end
    end
    render_response
  end

  private

    def coupon_params
      params.fetch(:coupon, {}).permit(:brand_id, :seller_id, :name, :code, :discount, :description, :expires_at, :url)
    end

    def invalid_authenticity_token
      if params.key?(:authenticity_token)
        @response[:data][:errors][:message] = ERROR_MESSAGE_CANT_VERIFY
      else
        create_response_error(:authenticity_token)
      end
      render_response
    end

    def create_response_error(param)
      @response[:data][:errors][:message] = @response[:data][:errors][:message].sub '%{param}', "#{param}"
    end

    def render_response
      render json: @response[:data], status: @response[:status], root: false
    end

end
