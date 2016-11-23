class Api::V1::PokemonGoUsersController < Api::BaseController
  # USER_PARAMS = {:access_token, :user_id, :name}

  def index
    render_success_response2 PokemonGoUser.order(:created_at).page(params[:page] || 1).per(RECORDS_PER_PAGE)
  end

  def show
    render_success_response2 PokemonGoUser.find(params[:id])
  end

  def create
    if !params[:user]
      create_response_error(:user)
      render_custom_error
    else
      create_response_error 'user[access_token]' unless params[:user][:access_token]
      create_response_error 'user[user_id]'      unless params[:user][:user_id]
      create_response_error 'user[name]'         unless params[:user][:name]
      create_response_error 'user[link]'         unless params[:user][:link]
      create_response_error 'user[picture]'      unless params[:user][:picture]
      # render_unsuccess_response
      # raise 'sdsdsd', :unprocessable_entity

      if @response[:data][:errors].empty?
        user = PokemonGoUser.find_by_user_id(user_params[:user_id])

        if user.nil?
          user = PokemonGoUser.new(user_params)

          if user.save
            render_success_response2 user, :created
          else
            render_custom_error user.errors
          end
        else
          render_success_response2 user
        end
      else
        render_custom_error
      end
    end
  end

  def update
  end

  def leader_board
    current_user = get_current_user(params[:pokemon_go_user_id])
    data = {
      leaders: PokemonGoUser.order(points_score: :desc).limit(3),
      user: current_user,
      user_rank: get_user_rank(current_user)
    }
    render_success_response2 data
  end

  def leader_board_weekly
    current_user = get_current_user(params[:pokemon_go_user_id])
    data = {
      leaders: PokemonGoUser.where("updated_at >= ?", Date.today - 1.week).order(points_score: :desc).limit(3),
      user: current_user,
      user_rank: get_user_rank(current_user)
    }
    render_success_response2 data
  end
  private

  def user_params
    params.fetch(:user, {}).permit(:access_token, :user_id, :name, :link, :locale, :picture, :lat, :lng)
  end

  def get_current_user(pokemon_go_user_id)
    if pokemon_go_user_id
      PokemonGoUser.find(pokemon_go_user_id)
    else
      nil
    end
  end

  def get_user_rank(user)
    PokemonGoUser.where("points_score > ?", user.points_score).count + 1 if user.present?
  end
end
