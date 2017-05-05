module ApplicationHelper
  def manager
    @manager ||= Account.find(current_user.own_account_id).account_detail.manager rescue ''
  end

  def account
    @account ||= begin
      Account.find(current_user.own_account_id)
    rescue ActiveRecord::RecordNotFound => error
      logger.error "#{self.class}##{__method__}: `own_account_id` is `nil`. #{error.class}: #{error.message}"
      current_user.accounts.first
    end
  end

  def account_detail
    @account_detail ||= account.account_detail
  end

  ##
  # Get tariff plan.
  def account_status
    @account_status ||= begin
      client = Client.find_by(ClientNumber: account.number.to_i)
      account_status = client ? client.client_fields.find_by(cltfieldID: ClientField::ACCOUNT_STATUS).try(:Field) : nil
      account_detail.tariff_plan || account_status || 'Free Trial'
    end
  end

  def account_number
    number_to_phone(account.number, area_code: true)
  end
end
