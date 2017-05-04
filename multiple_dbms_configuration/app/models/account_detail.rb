class AccountDetail < ApplicationRecord
  belongs_to :account
  belongs_to :manager
end
