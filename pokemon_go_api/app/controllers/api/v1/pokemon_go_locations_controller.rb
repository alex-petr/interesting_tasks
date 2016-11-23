class Api::V1::PokemonGoLocationsController < Api::BaseController
  def index
    user_location_point = [params[:lat], params[:lng]]

    # data = PokemonGoLocation.order(:created_at).limit(1000)#.page(params[:page] || 1).per(RECORDS_PER_PAGE)
    data = PokemonGoLocation.within(10, :origin => user_location_point)#.page(params[:page] || 1).per(RECORDS_PER_PAGE)
    if params[:for_pokemon_go_user_id]
      current_user = PokemonGoUser.find(params[:for_pokemon_go_user_id])
      render_success_response2 data, :ok, current_user
    elsif params[:pokemon_go_user_id]
      current_user = PokemonGoUser.find(params[:pokemon_go_user_id])
      render_success_response2 data, :ok, current_user
    else
      render_success_response2 data
    end
  end

  def show
   render_success_response2 PokemonGoLocation.find params[:id]
  end

  def create
    if !params[:location]
      create_response_error(:location)
      render_custom_error
    else
      create_response_error 'location[pokemon_go_user_id]' unless params[:location][:pokemon_go_user_id]
      create_response_error 'location[lat]'                unless params[:location][:lat]
      create_response_error 'location[lng]'                unless params[:location][:lng]
      create_response_error 'location[type]'               unless params[:location][:type]

      if @response[:data][:errors].empty?
        location = PokemonGoLocation.new(location_params)

        if location.save
          location.pokemon_go_user.update_points_score(0, 1)
          render_success_response2 location, :created
        else
          render_custom_error location.errors
        end
      else
        render_custom_error
      end
    end
  end

  def update
  end

  def up_vote
    create_response_error 'pokemon_go_user_id' unless params[:pokemon_go_user_id]

    if @response[:data][:errors].empty?
      location     = PokemonGoLocation.find(params[:pokemon_go_location_id])
      current_user = PokemonGoUser.find(params[:pokemon_go_user_id])
      prev_location_score = location.points_score

      if current_user.voted_for? location
        if current_user.voted_down_on? location
          location.upvote_by current_user
        else
          location.unvote_by current_user
        end
      else
        location.upvote_by current_user
      end

      if location.cached_votes_total >= 5
        points_score = location.calculate_points_score(location.cached_votes_up, location.cached_votes_total)
        location.pokemon_go_user.update_points_score(prev_location_score, points_score)
      end

      render_success_response2 location, :ok, current_user
    else
      render_custom_error
    end
  end

  def down_vote
    create_response_error 'pokemon_go_user_id' unless params[:pokemon_go_user_id]

    if @response[:data][:errors].empty?
      location     = PokemonGoLocation.find(params[:pokemon_go_location_id])
      current_user = PokemonGoUser.find(params[:pokemon_go_user_id])
      prev_location_score = location.points_score

      if current_user.voted_for? location
        if current_user.voted_up_on? location
          location.downvote_by current_user
        else
          location.unvote_by current_user
        end
      else
        location.downvote_by current_user
      end

      if location.cached_votes_total >= 5
        points_score = location.calculate_points_score(location.cached_votes_up, location.cached_votes_total)
        location.pokemon_go_user.update_points_score(prev_location_score, points_score)
      end

      render_success_response2 location, :ok, current_user
    else
      render_custom_error
    end
  end

  private

  def location_params
    # Convert `params[:location][:type] --> params[:location][:pokemon_go_location_type_id]`.
    @pokemon_go_location_types = {}
    PokemonGoLocationType.all.each { |type| @pokemon_go_location_types[type.key] = type.id }
    params[:location][:pokemon_go_location_type_id] = @pokemon_go_location_types[params[:location][:type]]

    params.fetch(:location, {}).permit(:pokemon_go_user_id, :title, :lat , :lng, :pokemon_go_location_type_id)
  end
end
