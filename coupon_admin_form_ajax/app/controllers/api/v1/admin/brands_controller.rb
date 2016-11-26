class Api::V1::Admin::BrandsController < Api::BaseController
  def index
    params[:page]     ||= 1
    params[:per_page] ||= 30

    brands = Brand.unscoped.where('name ILIKE ?', "%#{params[:query]}%").order(:id).page(params[:page]).per(params[:per_page])

    render json: brands,
           each_serializer: Api::V1::Admin::BrandSerializer,
           meta: {
             per_page: params[:per_page],
             total_pages: brands.total_pages,
             total_count: brands.total_count
           }
  end

  def create
    if !params[:brand]
      create_response_error(:brand)
      render_custom_error
    else
      create_response_error 'brand[name]' unless params[:brand][:name]

      if @response[:data][:errors].empty?
        brand = Brand.new(brand_params)

        if brand.save
          render_success_response2 brand, :created
        else
          render_custom_error brand.errors
        end
      else
        render_custom_error
      end
    end
  end

  private

  def brand_params
    params[:brand][:custom] = true
    params.fetch(:brand, {}).permit(:name, :custom)
  end
end
