class GamesController < ApplicationController
  def show
    @game  = Game.find_by_uuid!(params[:id])
    @match = @game.match


    render 'games/stats', locals: { final_stats: @match.game_over_stats } if @match.match_ended?

    unless @match.match_started?
      if @game.player_1? && @game.session_uuid == session[:session_uuid]
        @user_name        = @game.player_name
        @difficulty_level = @match.difficulty_level
        @challenge_url    = join_match_url(match_key: @match.match_key)
        render 'home/waiting_for_challenger'
      end
    end

    @board     = @match.starting_board
    @match_key = @match.match_key
    @game_uuid = @game.uuid
  end

  def check_input
    raise NotImplementedError.new("TODO: Move check_input to GamesController#check_input from GameController#check_input")
  end

  private

end
