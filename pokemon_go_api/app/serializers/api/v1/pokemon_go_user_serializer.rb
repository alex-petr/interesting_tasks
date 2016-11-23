class Api::V1::PokemonGoUserSerializer < ActiveModel::Serializer
  attributes :id, :access_token, :user_id, :name, :link, :locale, :picture, :lat, :lng, :points_score, :created_at,
             :updated_at

  def lat
    object.lat.to_f
  end

  def lng
    object.lng.to_f
  end
end
