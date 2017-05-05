class ErrorsMailer < ApplicationMailer
  def new_message_notification(account_info, message = '')
    support_email = ENV.fetch('SALES_MANAGER_EMAIL', 'LVsales@livevoice.com')
    @account_info = account_info
    @message      = message
    mail to: support_email, subject: 'New message from error page created'
  end
end
