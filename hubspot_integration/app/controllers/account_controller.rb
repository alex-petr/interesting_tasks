class AccountController < ApplicationController
  def create
    manager = Manager.get_random_manager
    assigned_number = FreeNumber.get_free_number.ClientNumber
    account = Account.create(name: params[:company_name], number: assigned_number)
    account_detail = account.create_account_detail(account_params.merge(manager_id: manager.id,
                                                                        tariff_plan: 'Free Trial'))

    HubspotService.new.create_company_contact_deal(first_name: current_user.first_name,
                                                   last_name: current_user.last_name,
                                                   email: current_user.email,
                                                   company_name: params[:company_name],
                                                   hubspot_owner_id: manager.HubSpot_id,
                                                   account_detail: account_detail,
                                                   assigned_number: assigned_number)
  end

  private

  def account_params
    params.require(:account).permit(:company_phone, :company_address_1, :company_address_2, :country, :city, :state,
                                    :postal_code, :website, :business_type, :time_zone, :office_hours, :line_answer,
                                    :delivery_email_flag, :delivery_sms_flag, :delivery_email, :delivery_phone,
                                    :coverage_times, :estimated_monthly_usage, :recordings_flag, :chat_flag,
                                    :transfers_flag, :knowledge_base_flag, :call_scripting_flag,
                                    :appointment_software_flag)
  end
end
