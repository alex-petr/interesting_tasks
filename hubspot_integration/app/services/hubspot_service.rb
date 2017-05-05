##
# Send client info to HubSpot:
# - create contact
# - create company
# - create deal
# Used after user/account creating.
# TODO: Move to ActiveJob/Sidekiq worker.
class HubspotService
  # INTERNAL VALUE => LABEL
  DEAL_STAGE_OPTIONS = {
    # 'a38d98d7-c8e9-468f-a52a-dd548e9aaf51' => 'Signed',
    # 'contractsent'                         => 'In Prog',
    # '763a874a-7ac7-4aa7-835d-17cbe273b063' => 'In Prog-pending info',
    'closedwon'                            => 'Free Trial',
    'closedlost'                           => 'Active'
    # '28e05fd7-dab9-47aa-8548-37a15b0137bf' => 'Cancelled Client',
    # '4379aa0e-8ec1-46fb-b99d-d75d8e5fa5e4' => 'Free Trial Expired',
    # '5e2bf9f5-afbb-4f28-8e51-367db5172a3a' => 'Inactivity',
    # 'cbe71e43-742c-48de-81b2-9f799bfa803a' => 'Non-Pay',
    # '13b1c870-ae62-443f-8e22-bf6112497edb' => 'Never launched'
  }

  ##
  # @return [Integer] deal_id
  def create_company_contact_deal(client_info)
    if ENV.fetch('HUBSPOT_KEY', '').empty? || ENV.fetch('HUBSPOT_PORTAL_ID', '').empty?
      return report_error("#{self.class}##{__method__}: `HUBSPOT_KEY` or `HUBSPOT_PORTAL_ID` is empty")
    end

    if client_info.fetch(:email, '').empty? || client_info.fetch(:company_name, '').empty?
      return report_error("#{self.class}##{__method__}: `email` or `company_name` in `client_info` is empty")
    end

    contact = create_or_update_contact(client_info)
    company = create_company(client_info)

    if contact && company
      add_contact_to_company(company, contact)
      create_deal(client_info, company, contact)
    end
  end

  ##
  # Get deal stage by deal id.
  # Allow only `Free Trial` or `Active`, any other stage will be `Disabled`.
  # @param [Integer] deal_id
  def get_deal_stage(deal_id)
    run_with_rescue { DEAL_STAGE_OPTIONS.fetch(Hubspot::Deal.find(deal_id).properties['dealstage'], 'Disabled') }
  end

  ##
  # Find or create HubSpot contact.
  # @param [String] email
  def find_or_create_contact(email)
    find_contact(email) || create_contact(email)
  end

  private

  ##
  # Find HubSpot contact.
  # @param [String] email
  # @return [Hubspot::Contact || nil] contact
  def find_contact(email)
    run_with_rescue { Hubspot::Contact.find_by_email(email) }
  end

  ##
  # Create/Update HubSpot contact.
  # @param [String] email
  def create_contact(email)
    run_with_rescue { Hubspot::Contact.create!(email, free_trial_duration: '7', lifecyclestage: 'lead') }
  end

  ##
  # Create/Update HubSpot contact.
  # TODO: simplify
  # def create_or_update_contact(email, params)
  #   run_with_rescue { Hubspot::Contact.createOrUpdate(email, params) }
  # @param [Hash] client_info
  def create_or_update_contact(client_info)
    run_with_rescue do
      Hubspot::Contact.createOrUpdate(client_info[:email],
                                      firstname: client_info[:first_name],
                                      lastname: client_info[:last_name],
                                      hubspot_owner_id: client_info[:hubspot_owner_id],
                                      website: client_info[:account_detail].website,
                                      company: client_info[:company_name],
                                      phone: client_info[:account_detail].company_phone,
                                      address: client_info[:account_detail].company_address_1,
                                      city: client_info[:account_detail].city,
                                      state: client_info[:account_detail].state,
                                      zip: client_info[:account_detail].postal_code,
                                      free_trial_duration: '7',
                                      lifecyclestage: 'lead')
    end
  end

  ##
  # Create HubSpot company.
  # @param [Hash] client_info
  def create_company(client_info)
    run_with_rescue do
      Hubspot::Company.create!(client_info[:company_name],
                               zip: client_info[:account_detail].postal_code,
                               website: client_info[:account_detail].website,
                               domain: get_domain_from_website(client_info[:account_detail].website),
                               city: client_info[:account_detail].city,
                               industry: client_info[:account_detail].business_type,
                               phone: client_info[:account_detail].company_phone,
                               state: client_info[:account_detail].state,
                               timezone: client_info[:account_detail].time_zone,
                               hubspot_owner_id: client_info[:hubspot_owner_id],
                               address: client_info[:account_detail].company_address_1)
    end
  end

  ##
  # Add HubSpot contact to company.
  # @param [Hubspot::Company] company
  # @param [Hubspot::Contact] contact
  def add_contact_to_company(company, contact)
    run_with_rescue { company.add_contact(contact) }
  end

  ##
  # Create HubSpot deal.
  # @param [Hash] client_info
  # @param [Hubspot::Company] company
  # @param [Hubspot::Contact] contact
  # @return [Integer] deal_id
  def create_deal(client_info, company, contact)
    run_with_rescue do
      Hubspot::Deal.create!(ENV['HUBSPOT_PORTAL_ID'], [company.vid], [contact.vid],
                            pipeline: 'default',
                            dealstage: 'closedwon',
                            closedate: Time.now.to_i * 1000,
                            dealname: client_info[:company_name],
                            hubspot_owner_id: client_info[:hubspot_owner_id],
                            amount: '0',
                            dealtype: 'Free Trial',
                            trial: 'Free Trial',
                            did: client_info[:assigned_number]).deal_id
    end
  end

  ##
  # Run Hubspot module methods with rescue Hubspot::RequestError.
  # @return [FalseClass]
  def run_with_rescue
    yield
  rescue Hubspot::RequestError => error
    called_method = "#{self.class}##{caller_locations(2).first.label}"
    report_error("#{called_method}: #{error.class}: #{error.message}", "#{called_method}", error)
    false
  end

  ##
  # Log error to Rails log and report about exception to Rollbar for staging/production.
  # @param [String] logger_message
  # @param [String] rollbar_message
  # @param [Exception] error
  def report_error(logger_message, rollbar_message = nil, error = nil)
    Rails.logger.error(logger_message)
    Rollbar.error(rollbar_message || logger_message, error) if Rails.env.staging? || Rails.env.production?
  end

  ##
  # Get domain from website.
  # TODO: Simplify this!
  # @param [String] website
  # @return [String] domain
  def get_domain_from_website(website)
    (URI.parse(website)&.host.to_s.match(/[^\.]+\.\w+$/) || website.gsub(/^www./,'').gsub(/\/.*$/,'')).to_s
  end
end
