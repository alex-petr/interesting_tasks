class Api::V1::Admin::SellersController < Api::BaseController
  def index
    params[:page]     ||= 1
    params[:per_page] ||= 30

    sellers = Seller.unscoped.where('name ILIKE ?', "%#{params[:query]}%").order(:id).page(params[:page]).per(params[:per_page])

    render json: sellers,
           each_serializer: Api::V1::Admin::SellerSerializer,
           meta: {
             per_page: params[:per_page],
             total_pages: sellers.total_pages,
             total_count: sellers.total_count
           }
  end

  def create
    if !params[:seller]
      create_response_error(:seller)
      render_custom_error
    else
      create_response_error 'seller[name]' unless params[:seller][:name]

      if @response[:data][:errors].empty?
        seller = Seller.new(seller_params)

        if seller.save
          render_success_response2 seller, :created
        else
          render_custom_error seller.errors
        end
      else
        render_custom_error
      end
    end
  end

  private

  def seller_params
    params[:seller][:custom] = true
    params.fetch(:seller, {}).permit(:name, :custom)
  end
end
