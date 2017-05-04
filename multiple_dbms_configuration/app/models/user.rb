class User < ApplicationRecord
  self.table_name = 'live_voice_users'

  has_and_belongs_to_many :accounts, class_name: 'Account', join_table: 'live_voice_accounts_users',
                          foreign_key: 'live_voice_user_id', association_foreign_key: 'live_voice_account_id'

  # after_create :send_welcome_mail

  devise :database_authenticatable, :recoverable, :rememberable, :registerable,
         :trackable, :validatable, :lockable, :timeoutable

  private

  def send_welcome_mail
    UserMailer.send_welcome_mail(self).deliver_later
  end
end
