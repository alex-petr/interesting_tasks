class Account < ApplicationRecord
  self.table_name = 'live_voice_accounts'

  has_one :account_detail
  has_and_belongs_to_many :users, class_name: 'User', join_table: 'live_voice_accounts_users',
                          foreign_key: 'live_voice_account_id', association_foreign_key: 'live_voice_user_id'

  validates :name,   presence: true
  validates :number, presence: true
end
