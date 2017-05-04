class ClientField < SqlServerRecord
  if Rails.env.production?
    establish_connection :sql_server_amtelco_internal
    self.table_name = :dirListingFields
  else
    establish_connection :sql_server_amtelco_custom
    self.table_name = :dirListingFields_copy
  end

  # Constants of cltFieldID's for data updating
  STATUS_CHANGE_DATE = 1 # previously `ANY_DATA`
  COMPANY_ADDRESS_1  = 2
  COMPANY_ADDRESS_2  = 3
  BACKLINE_PHONE     = 4 # Not used
  BUSINESS_TYPE      = 5
  CF_PHONE           = 6 # = Call Forwarding number, Not used
  CITY_STATE_ZIP     = 7
  COMPANY_NAME       = 8
  DID_PHONE          = 9 # = Direct Inward Dialing -- Phone call-center number assigned to client
  E_MAIL_LOGIN       = 10
  FAX_PHONE          = 11 # Not used
  CLIENT_NAME        = 12 # First Name & Last Name
  OFFICE_PHONE       = 13
  OFFICE_HOURS_1     = 14
  OFFICE_HOURS_2     = 15
  PRIVATE_PHONE      = 16 # Not used
  ROUTINE_CONSULT    = 17
  SPECIALTY          = 18 # Not used
  STAT_CONSULT       = 19 # Not used
  OFFICE_STATUS      = 20 # Not used
  WEBSITE            = 21
  NOTIFY_EMAIL       = 28
  NOTIFY_SMS         = 29
  ANSWER_PHRASE      = 30
  TIME_ZONE          = 31
  ACCOUNT_STATUS     = 32 # Default to `Free Trial`

  # Constants of DataType's for data type updating
  DATATYPE_TEXT    = 0
  DATATYPE_PHONE   = 1
  DATATYPE_DATE    = 2 # Format: `m/d/yyyy hh:mm:ss AM|PM`, example: `3/27/2017 10:38:16 AM`
  DATATYPE_WEBSITE = 3
  DATATYPE_EMAIL   = 4

  belongs_to :client

  ##
  # Split office hours string if length > 100 characters to two strings for MS SQL updating.
  def self.split_office_hours(client_fields)
    if client_fields.fetch(:office_hours_1, '').length > 100
      client_fields[:office_hours_2] = client_fields[:office_hours_1][100..-1]
      client_fields[:office_hours_1] = client_fields[:office_hours_1][0..99]
    end
    client_fields
  end
end
