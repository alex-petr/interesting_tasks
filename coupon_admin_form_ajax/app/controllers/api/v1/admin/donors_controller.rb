class Api::V1::Admin::DonorsController < Api::BaseController
  ALLOWED = '_qwertyuiopasdfghjklzxcvbnmQWERTYUIOPLKJHGFDSAZXCVBNM'

  def index
    params[:page]     ||= 1
    params[:per_page] ||= 30

    donors = Donor.unscoped.where('domain ILIKE ?', "%#{params[:query]}%").order(:id).page(params[:page]).per(params[:per_page])

    render json: donors,
           each_serializer: Api::V1::Admin::DonorSerializer,
           meta: {
             per_page: params[:per_page],
             total_pages: donors.total_pages,
             total_count: donors.total_count
           }
  end

  def create
    if !params[:donor]
      create_response_error(:donor)
      render_custom_error
    else
      create_response_error 'donor[domain]' unless params[:donor][:domain]

      if @response[:data][:errors].empty?
        donor = Donor.new(donor_params)

        if donor.save
          render_success_response2 donor, :created
        else
          render_custom_error donor.errors
        end
      else
        render_custom_error
      end
    end
  end

  private

  def donor_params
    params[:donor][:parser_class] = process_parser_class params[:donor][:domain]
    params[:donor][:custom]       = true
    params.fetch(:donor, {}).permit(:domain, :parser_class, :custom)
  end

  def process_parser_class(domain)
    path = ''
    domain.each_char { |c| path << c if ALLOWED.include?(c) }
    path.gsub('www', '').titleize.squish
  end
end
