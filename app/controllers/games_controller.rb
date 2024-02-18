class GamesController < ApplicationController
  def show
    @game  = Game.find_by_uuid!(params[:id])
    @match = @game.match

    if @match.match_ended?
      stats = @match.game_over_stats
      # TODO: Fix this view.
      #   In the normal flow, when a game is over, the stats get swapped in for the #gameContainer div
      #   but since the stats partial is getting loaded in by itself here, the layout is missing and
      #   the view looks barren (not centered, missing fonts, bootstrap buttons, etc)
      render partial: 'game/stats', locals: { final_stats: stats }
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
