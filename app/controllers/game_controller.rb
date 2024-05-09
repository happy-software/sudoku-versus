class GameController < ApplicationController
  def check_input
    # TODO - Deprecate this controller and move this action to GamesController
    match_key      = params[:match_id]
    game_id        = params[:game_id]
    selected_cell  = params[:selected_cell]
    selected_value = params[:selected_value]


    match = Match.find_by_match_key!(match_key)
    # TODO Make this a custom error that responds to the front end with a meaningful response
    #   so that the front end can do something about it (e.g. redirect to the stats page?)
    raise StandardError.new("Cannot make changes to a game after match has ended!") if match.match_ended?
    is_correct = match.solution.fetch(selected_cell.to_i).to_i == selected_value.to_i

    game = Game.find_by_uuid!(game_id)
    game.record_selection!(selected_value, selected_cell, is_correct)

    if game.game_over?
      match.set_end_time!
      stats          = match.game_over_stats
      player_1_game_over_html = render_to_string("game/_stats", layout: false, locals: { final_stats: stats, game_uuid: match.player_1_game.uuid, opponent_game_uuid: match.player_2_game.uuid })
      player_2_game_over_html = render_to_string("game/_stats", layout: false, locals: { final_stats: stats, game_uuid: match.player_2_game.uuid, opponent_game_uuid: match.player_1_game.uuid })

      Turbo::StreamsChannel.broadcast_replace_to(match.player_1_session, target: 'gameContainer', html: player_1_game_over_html)
      Turbo::StreamsChannel.broadcast_replace_to(match.player_2_session, target: 'gameContainer', html: player_2_game_over_html)

      render json: { game_over: true }
    else
      render json: { is_correct: is_correct, remaining_numbers: game.remaining_numbers }
    end
  end

end
