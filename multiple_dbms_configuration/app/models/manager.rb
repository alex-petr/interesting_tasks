class Manager < SqlServerRecord
  establish_connection :sql_server_amtelco_custom
  self.table_name = :LVAccountManagers

  has_many :account_details

  def self.get_random_manager
    self.count > 0 ? self.find(self.pluck(:id).shuffle.first) : nil
  end
end
