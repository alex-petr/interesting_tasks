class SessionsController < Devise::SessionsController
  after_action :after_login, :only => :create

  def after_login
    update_account_status
  end

  def update_account_status
    hubspot_deal_stage = HubspotService.new.get_deal_stage(helpers.account_detail.hubspot_deal_id)
    helpers.account_detail.update(tariff_plan: hubspot_deal_stage) if hubspot_deal_stage
  end
end
