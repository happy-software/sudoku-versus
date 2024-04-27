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

  def create_rematch
    game = Game.find_by_uuid!(params[:game_uuid])
    # TODO: Create a RematchRequest model:
    #  class CreateRematchRequests < ActiveRecord::Migration[7.0]
    #    def change
    #      create_table :rematch_requests do |t|
    #        t.references :challenger_game, null: false, foreign_key: { to_table: :games }
    #        t.references :challengee_game, null: false, foreign_key: { to_table: :games }
    #        t.references :match, null: false, foreign_key: true
    #        t.datetime :accepted_at
    #        t.timestamps
    #      end
    #    end
    #  end
    #  class RematchRequest < ApplicationRecord
    #    belongs_to :challenger_game, class_name: "Game"
    #    belongs_to :challengee_game, class_name: "Game"
    #    belongs_to :match
    #    def accept!
    #      self.accepted_at = DateTime.now
    #      self.save!
    #    end
    #    def accepted?
    #      self.accepted_at?
    #    end
    #  end

    rematch_request = RematchRequest.new
    rematch_request.challenger_game = game
    rematch_request.match = game.match
    rematch_request.challengee_game = game.match.player_1_game.uuid == game.uuid ? game.match.player_2_game : game
    rematch_request.save!

    @challenger_game_uuid = rematch_request.challenger_game.uuid
    @challengee_game_uuid = rematch_request.challengee_game.uuid

    Turbo::StreamsChannel.broadcast_replace_to(
      game.match.match_key,
      target: "rematch_request_container_#{@challengee_game_uuid}",
      partial: "game/rematch_request",
      locals: { challengee_game_uuid: @challengee_game_uuid}
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("send_rematch_request_#{@challenger_game_uuid}", partial: "game/rematch_challenge_sent"),
        ]
      end
    end
  end

  def accept_rematch
    puts "Accepting Rematch with these params: #{params}"
    game              = Game.find_by_uuid!(params[:game_uuid])
    original_match    = game.match
    accepting_player  = game.player_name
    requesting_player = game.player_number == "player_1" ? original_match.player_2_game.player_name : original_match.player_1_game.player_name


  end

  def reject_rematch
    puts "Rejecting Rematch with these params: #{params}"
  end
end
