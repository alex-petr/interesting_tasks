# == Schema Information
#
# Table name: pokemon_go_locations
#
#  id                          :integer          not null, primary key
#  pokemon_go_user_id          :integer
#  title                       :string
#  lat                         :decimal(11, 8)
#  lng                         :decimal(11, 8)
#  points_score                :integer          default(1), not null
#  pokemon_go_location_type_id :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  cached_votes_total          :integer          default(0)
#  cached_votes_score          :integer          default(0)
#  cached_votes_up             :integer          default(0)
#  cached_votes_down           :integer          default(0)
#  cached_weighted_score       :integer          default(0)
#  cached_weighted_total       :integer          default(0)
#  cached_weighted_average     :float            default(0.0)
#
# Indexes
#
#  index_pokemon_go_locations_on_cached_votes_down        (cached_votes_down)
#  index_pokemon_go_locations_on_cached_votes_score       (cached_votes_score)
#  index_pokemon_go_locations_on_cached_votes_total       (cached_votes_total)
#  index_pokemon_go_locations_on_cached_votes_up          (cached_votes_up)
#  index_pokemon_go_locations_on_cached_weighted_average  (cached_weighted_average)
#  index_pokemon_go_locations_on_cached_weighted_score    (cached_weighted_score)
#  index_pokemon_go_locations_on_cached_weighted_total    (cached_weighted_total)
#  index_pokemon_go_locations_on_lat                      (lat)
#  index_pokemon_go_locations_on_lat_and_lng              (lat,lng)
#  index_pokemon_go_locations_on_lng                      (lng)
#  index_pokemon_go_locations_on_pokemon_go_user_id       (pokemon_go_user_id)
#

class PokemonGoLocation < ActiveRecord::Base
  belongs_to :pokemon_go_user

  has_one :pokemon_go_location_type

  acts_as_votable
  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :distance_field_name => :distance,
                   :lat_column_name => :lat,
                   :lng_column_name => :lng

  validates_presence_of :pokemon_go_user_id, :lat, :lng, :pokemon_go_location_type_id
  validates_uniqueness_of :lat, scope: [:pokemon_go_user_id, :lng]

  def calculate_points_score(up_votes, total_votes)
    return 0 if total_votes < 5

    percent = up_votes.to_f / total_votes * 100
    score = if percent <= 50
              -1
            elsif percent >= 75 && percent < 90
              1
            elsif percent >= 90
              2
            else
              0
            end

    self.update(points_score: 1 + score) unless score.zero?
    score
  end
end
