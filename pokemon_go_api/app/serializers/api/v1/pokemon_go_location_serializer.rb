class Api::V1::PokemonGoLocationSerializer < ActiveModel::Serializer
  attributes :id, :pokemon_go_user_id, :pokemon_go_user, :title, :lat , :lng, :points_score, :type,
             :down_votes, :up_votes, :voted, :created_at, :updated_at

  def lat
    object.lat.to_f
  end

  def lng
    object.lng.to_f
  end

  def pokemon_go_user
    PokemonGoUser.find(object.pokemon_go_user_id)
  end

  def type
    if object.pokemon_go_location_type_id.nil?
      ''
    else
      PokemonGoLocationType.find(object.pokemon_go_location_type_id).key
    end
  end

  def down_votes
    object.get_downvotes.size
  end

  def up_votes
    object.get_upvotes.size
  end

  def voted
    user = serialization_options[:scope]
    return nil unless user

    if user.voted_up_on? object
      1
    elsif user.voted_down_on? object
      -1
    else
      0
    end
  end
end
