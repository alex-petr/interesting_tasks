# == Schema Information
#
# Table name: pokemon_go_users
#
#  id           :integer          not null, primary key
#  access_token :string
#  user_id      :string
#  name         :string
#  link         :string
#  locale       :string
#  picture      :string
#  lat          :decimal(11, 8)
#  lng          :decimal(11, 8)
#  points_score :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_pokemon_go_users_on_lat          (lat)
#  index_pokemon_go_users_on_lat_and_lng  (lat,lng)
#  index_pokemon_go_users_on_lng          (lng)
#

class PokemonGoUser < ActiveRecord::Base
  has_many :pokemon_go_locations

  acts_as_voter

  validates :access_token, :user_id, presence: true, uniqueness: true

  def update_points_score(prev_location_score, points_score)
    self.update(points_score: (self.points_score + points_score - prev_location_score))
  end
end
