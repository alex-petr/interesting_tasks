class ErrorsController < ApplicationController
  def not_found
    render status: 404
  end

  def internal_server_error
    render status: 500
  end

  # POST /error-message
  def send_message
    account_info = if user_signed_in?
                     {name: user_name, email: current_user.email, account_name: helpers.account.name,
                      account_number: helpers.account.number}
                   else
                     {email: params['errors'].fetch(:email, '')}
                   end
    flash[:is_message_submitted] = true
    ErrorsMailer.new_message_notification(account_info, message_params.to_hash.symbolize_keys[:message]).deliver_later
    redirect_to request.referer
  end

  private

  def message_params
    params.require(:errors).permit(:message)
  end
end
