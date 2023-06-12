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

    if game.game_over?
      stats = match.game_over_stats
      game_over_html = render_to_string("game/_stats", layout: false, locals: { final_stats: stats })

      Turbo::StreamsChannel.broadcast_replace_to(match.match_key, target: 'waiting_for_challenger_container', html: game_over_html)
      Turbo::StreamsChannel.broadcast_replace_to(match.match_key, target: 'player_2_accept_challenge_container', html: game_over_html)
    else
      render json: { is_correct: is_correct, game_over: game.game_over? }
    end
  end
end
