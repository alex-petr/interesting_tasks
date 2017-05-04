class Client < SqlServerRecord
  if Rails.env.production?
    establish_connection :sql_server_amtelco_internal
    self.table_name = :cltClients
  else
    establish_connection :sql_server_amtelco_custom
    self.table_name = :cltClients_copy
  end

  has_many :client_fields, foreign_key: 'cltID'

  ##
  # Update single ClientField by `field_id` if `field_value` is present.
  # @param [Fixnum] field_id
  # @param [String] field_value
  # @param [Fixnum] field_type
  def update_client_field(field_id, field_value, field_type)
    if field_value.present?
      ClientField.where(cltID: self.cltId, cltfieldID: field_id).update_all(Field: field_value, DataType: field_type)
    end
  end

  ##
  # Update ClientFields by `client_number` and field names.
  # @param [String] client_number
  # @param [Hash] field_values
  def self.update_client_fields(client_number, field_values = {})
    client_number = client_number.to_i
    client = self.find_by(ClientNumber: client_number)
    if client
      # For `field_values.fetch(:key_name, '')` correct work
      field_values.symbolize_keys!

      field_values = ClientField.split_office_hours(field_values)

      user_name = [field_values.fetch(:user_first_name, ''), field_values.fetch(:user_last_name, '')]
                      .reject(&:empty?).join(' ')
      country_city_state = [field_values.fetch(:country, ''), field_values.fetch(:state, ''),
                            field_values.fetch(:city, ''),    field_values.fetch(:postal_code, '')]
                               .reject(&:empty?).join(', ')

      # ClientName updating
      client_name = field_values.fetch(:company_name, user_name)
      client.update(ClientName: client_name) if client_name.present?

      [
        {id: ClientField::DID_PHONE,          data: client_number,                               type: ClientField::DATATYPE_PHONE},
        {id: ClientField::E_MAIL_LOGIN,       data: field_values.fetch(:user_email, ''),         type: ClientField::DATATYPE_EMAIL},
        {id: ClientField::CLIENT_NAME,        data: user_name,                                   type: ClientField::DATATYPE_TEXT},
        {id: ClientField::COMPANY_NAME,       data: client_name,                                 type: ClientField::DATATYPE_TEXT},
        {id: ClientField::CITY_STATE_ZIP,     data: country_city_state,                          type: ClientField::DATATYPE_TEXT},
        {id: ClientField::COMPANY_ADDRESS_1,  data: field_values.fetch(:company_address_1, ''),  type: ClientField::DATATYPE_TEXT},
        {id: ClientField::COMPANY_ADDRESS_2,  data: field_values.fetch(:company_address_2, ''),  type: ClientField::DATATYPE_TEXT},
        {id: ClientField::OFFICE_PHONE,       data: field_values.fetch(:company_phone, ''),      type: ClientField::DATATYPE_PHONE},
        {id: ClientField::BUSINESS_TYPE,      data: field_values.fetch(:business_type, ''),      type: ClientField::DATATYPE_TEXT},
        {id: ClientField::ROUTINE_CONSULT,    data: field_values.fetch(:manager_name, ''),       type: ClientField::DATATYPE_TEXT},
        {id: ClientField::OFFICE_HOURS_1,     data: field_values.fetch(:office_hours_1, ''),     type: ClientField::DATATYPE_TEXT},
        {id: ClientField::OFFICE_HOURS_2,     data: field_values.fetch(:office_hours_2, ''),     type: ClientField::DATATYPE_TEXT},
        {id: ClientField::WEBSITE,            data: field_values.fetch(:website, ''),            type: ClientField::DATATYPE_WEBSITE},
        {id: ClientField::NOTIFY_EMAIL,       data: field_values.fetch(:delivery_email, ''),     type: ClientField::DATATYPE_EMAIL},
        {id: ClientField::NOTIFY_SMS,         data: field_values.fetch(:delivery_phone, '').delete('^0-9'),     type: ClientField::DATATYPE_PHONE},
        {id: ClientField::ANSWER_PHRASE,      data: field_values.fetch(:line_answer, ''),        type: ClientField::DATATYPE_TEXT},
        {id: ClientField::TIME_ZONE,          data: field_values.fetch(:time_zone, ''),          type: ClientField::DATATYPE_TEXT},
        {id: ClientField::ACCOUNT_STATUS,     data: field_values.fetch(:account_status, ''),     type: ClientField::DATATYPE_TEXT},
        {id: ClientField::STATUS_CHANGE_DATE, data: field_values.fetch(:account_created_at, ''), type: ClientField::DATATYPE_DATE},
      ]
        .each { |field| client.update_client_field(field[:id], field[:data], field[:type]) }
    end
  end
end
