class GamesController < ApplicationController
  def show
    @game  = Game.find_by_uuid!(params[:id])
    @match = @game.match


    render 'games/stats', locals: { final_stats: @match.game_over_stats, game_uuid: @game.uuid } if @match.match_ended?

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

  def create_rematch
    game                            = Game.find_by_uuid!(params[:game_id])
    original_match                  = game.match
    rematch_request                 = RematchRequest.new
    rematch_request.challenger_game = game
    rematch_request.match           = original_match
    rematch_request.challengee_game = game.player_1? ? original_match.player_2_game : original_match.player_1_game
    rematch_request.save!

    @challenger_game_uuid = rematch_request.challenger_game.uuid
    @challengee_game_uuid = rematch_request.challengee_game.uuid

    Turbo::StreamsChannel.broadcast_replace_to(
      original_match.match_key,
      target: "rematch_request_container_#{@challengee_game_uuid}",
      partial: "game/rematch_request",
      locals: { challengee_game_uuid: @challengee_game_uuid}
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("send_rematch_request_#{@challenger_game_uuid}",
                              partial: "game/rematch_challenge_sent"),
        ]
      end
    end
  end

  def accept_rematch
    game              = Game.find_by_uuid!(params[:game_id])
    original_match    = game.match
    accepting_player  = game.player_name
    requesting_player = game.player_1? ? original_match.player_2_game.player_name : original_match.player_1_game.player_name

    accepting_player_session  = game.session_uuid
    requesting_player_session = game.player_1? ? original_match.player_2_game.session_uuid : original_match.player_1_game.session_uuid

    board                     = SudokuBuilder.create
    solution                  = board.to_a.flatten
    original_difficulty_level = original_match.starting_board.count(nil)
    starting_board            = board.poke(original_difficulty_level).to_a.flatten
    match_key                 = SecureRandom.uuid

    match = Match.create!(starting_board:   starting_board,
                  solution:         solution,
                  match_key:        match_key,
                  player_1_name:    requesting_player,
                  player_2_name:    accepting_player,
                  difficulty_level: original_match.difficulty_level,
                  )
    match.set_start_time!

    player_1_game = match.games.create!(player_number: :player_1,
                                        player_name:   requesting_player,
                                        uuid:          SecureRandom.uuid,
                                        session_uuid:  requesting_player_session)

    player_2_game = match.games.create!(player_number: :player_2,
                                        player_name:   accepting_player,
                                        uuid:          SecureRandom.uuid,
                                        session_uuid:  accepting_player_session)
    requesting_player_redirect_message = render_to_string("games/_rematch_accepted",
                                                          layout: false,
                                                          local_assigns: {redirect_url: game_url(player_1_game.uuid)},
                                                          locals: {redirect_url: game_url(player_1_game.uuid)},
                                                          )
    accepting_player_redirect_message = render_to_string("games/_rematch_accepted",
                                                          layout: false,
                                                          local_assigns: {redirect_url: game_url(player_2_game.uuid)},
                                                         locals: {redirect_url: game_url(player_2_game.uuid)},
                                                         )
    Turbo::StreamsChannel.broadcast_replace_to(requesting_player_session,
                                               target: 'play_again',
                                               html: requesting_player_redirect_message)
    Turbo::StreamsChannel.broadcast_replace_to(accepting_player_session,
                                               target: 'play_again',
                                               html: accepting_player_redirect_message)
  end

  def reject_rematch
    # TODO: Send a message back to the challenger that the request was declined.
  end

  private

end
