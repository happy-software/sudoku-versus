class HomeController < ApplicationController
  def index
    @recent_games = Match.recently_ended.first(15).map { |match| match.game_over_stats.merge(difficulty_level: match.difficulty_level.titleize)}
  end

  def new
  end

  def create_challenge
    session[:user_name]    ||= params[:user_name_input].titleize

    @user_name        = session[:user_name]
    @difficulty_level = params[:difficulty_level]
    @match            = create_new_match(difficulty: @difficulty_level.to_s, player_1_name: @user_name, player_1_session_uuid: session[:session_uuid])
    @challenge_url    = join_match_url(match_key: @match.match_key)

    puts "#{@user_name} has created a challenge (match: #{@match.match_key})"
    redirect_to game_path(@match.player_1_game.uuid)
  end

  def join_match
    match         = Match.find_by!(match_key: params[:match_key])
    existing_game = match.games.find_by_session_uuid(session[:session_uuid])
    redirect_to game_path(existing_game.uuid) if existing_game.present?

    redirect_to new_path if match.match_started?

    @player_1_name    = match.player_1_name
    @match_key        = match.match_key
    @difficulty_level = match.difficulty_level

    puts "Player 2 looking to join #{@difficulty_level} match(#{@match_key}) against #{@player_1_name}"
  end

  def accept_challenge
    session[:user_name] ||= params[:user_name_input].titleize
    @user_name = session[:user_name]

    match = Match.find_by!(match_key: params[:match_key])
    match.player_2_name = @user_name
    match.save!

    player_2_game = match.games.create!(player_number: :player_2, player_name: match.player_2_name, uuid: SecureRandom.uuid, session_uuid: session[:session_uuid])

    @board = match.starting_board

    game_1_html = render_to_string("games/show", layout: false, assigns: {game: match.player_1_game, board: @board, match: match, match_key: match.match_key, game_uuid: match.player_1_game.uuid})
    match.set_start_time!

    puts "Player 2 (#{@user_name}) accepting challenge for match(#{match.match_key}) against Player 1 (#{match.player_1_game.player_name})"
    Turbo::StreamsChannel.broadcast_replace_to(match.match_key, target: 'waiting_for_challenger_container', html: game_1_html)
    redirect_to game_path(player_2_game.uuid)
  end

  private

  def create_new_match(difficulty:, player_1_name:, player_1_session_uuid:)
    difficulty_level = if difficulty.to_s.downcase == 'easy'
      (25..32).to_a.sample
    elsif difficulty.to_s.downcase == 'medium'
      (31..39).to_a.sample
    elsif difficulty.to_s.downcase == 'hard'
      (38..46).to_a.sample
    elsif difficulty.to_s.downcase == 'very_hard'
      (55..65).to_a.sample
    else
      ArgumentError.new("Given difficulty level: (#{difficulty}) is not recognized! Possible Options: (Easy, Medium, Hard, Very Hard)")
    end

    board          = SudokuBuilder.create
    solution       = board.to_a.flatten
    starting_board = ApplicationHelper.poke(solution, difficulty_level)
    match_key      = SecureRandom.uuid
    match          = Match.create!(starting_board: starting_board, solution: solution, match_key: match_key, player_1_name: player_1_name, difficulty_level: difficulty)

    match.games.create!(player_number: :player_1, player_name: player_1_name, uuid: SecureRandom.uuid, session_uuid: player_1_session_uuid)

    match
  end
end
