class FreeNumber < SqlServerRecord
  establish_connection :sql_server_amtelco_custom
  if Rails.env.production?
    self.table_name = :FreeTrialDID
  else
    self.table_name = :FreeTrialDID_copy
  end

  def self.free_numbers
    self.where("Active IS NULL OR Active = ''")
  end

  def self.get_free_number
    self.free_numbers.first
  end
end
