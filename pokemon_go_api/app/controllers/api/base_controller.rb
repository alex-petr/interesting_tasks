class Api::BaseController < ActionController::Base
  ERROR_MESSAGE_INCLUDE_PARAM = 'Please include `%{param}` parameter in request'
  ERROR_MESSAGE_NOT_FOUND     = 'Couldn\'t find record with `id`=`%{param}`'
  ERROR_MESSAGE_CANT_VERIFY   = 'Can\'t verify CSRF token authenticity'

  RECORDS_PER_PAGE = 10

  respond_to :json

  rescue_from Exception, :with => :render_error
  rescue_from StandardError, :with => :render_error
  rescue_from ActiveRecord::RecordInvalid, :with => :render_unsuccess_response
  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found

  def initialize
    @response = {
      data: { errors: [] }, #{ message: ERROR_MESSAGE_INCLUDE_PARAM }
      status: :unprocessable_entity # :bad_request
    }
  end

  def render_response(data = nil, status = :ok)
    if @response[:data][:errors].empty?
      render_success_response2 data, status
    else
      render_custom_error
    end
    # render json: @response[:data], meta: {success: true}, status: @response[:status], root: 'result'
  end

  def render_success_response(data)
    @response = { data: data, status: :ok }
    render_response
  end

  def render_unsuccess_response(e = nil)
    render json: {error: [e.message], meta: {success: false}}, status: :unprocessable_entity
  end

  def render_not_found(error = nil)
    # @response[:data][:errors][:message] = ERROR_MESSAGE_NOT_FOUND
    # create_response_error(params[:id])
    # @response[:status] = :not_found
    # render_response
    render json: {error: [error.message], meta: {success: false}}, status: :not_found
  end

  def create_response_error(param)
    @response[:data][:errors] << ERROR_MESSAGE_INCLUDE_PARAM.sub('%{param}', "#{param}")
  end

  def render_error(error)
    Rails.logger.error "Exception caught caused return 500 : #{error.message}"
    Rails.logger.debug error.backtrace.join("\n")
    render json: {error: [error.message], meta: {success: false}}, status: :internal_server_error
  end

  def render_custom_error(message = @response[:data][:errors], status = :unprocessable_entity)
    render json: {error: message, meta: {success: false}}, status: status
  end

  def render_success_response2(data = nil, status = :ok, scope = nil)
    if !scope.blank?
      render json: data, scope: scope, meta: {success: true}, status: status, root: 'result'
    else
      render json: data, meta: {success: true}, status: status, root: 'result'
    end
  end
end
