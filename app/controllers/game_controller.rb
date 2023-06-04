class GameController < ApplicationController
  def check_input
    match_key      = params[:match_id]
    game_id        = params[:game_id]
    selected_cell  = params[:selected_cell]
    selected_value = params[:selected_value]

    match = Match.find_by_match_key!(match_key)
    is_correct = match.solution.fetch(selected_cell.to_i).to_i == selected_value.to_i

    game = Game.find_by_uuid!(game_id)
    game.record_selection!(selected_value, selected_cell, is_correct)

    render json: { is_correct: is_correct, game_over: game.game_over? }
  end
end
