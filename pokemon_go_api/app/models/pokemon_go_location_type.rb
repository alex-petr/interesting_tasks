# == Schema Information
#
# Table name: pokemon_go_location_types
#
#  id         :integer          not null, primary key
#  name       :string
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PokemonGoLocationType < ActiveRecord::Base
  belongs_to :pokemon_go_location

  validates :name, :key, presence: true, uniqueness: true
end
