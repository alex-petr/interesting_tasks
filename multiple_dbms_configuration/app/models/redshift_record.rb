class RedshiftRecord < ApplicationRecord
  establish_connection :redshift
  self.abstract_class = true
end
