class GamesController < ApplicationController
  def show
    @game      = Game.find_by_uuid!(params[:id])
    @match     = @game.match
    @board     = @match.starting_board
    @match_key = @match.match_key
    @game_uuid = @game.uuid
  end

  def check_input
    raise NotImplementedError.new("TODO: Move check_input to GamesController#check_input from GameController#check_input")
  end

  private

end
