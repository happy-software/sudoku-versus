class HomeController < ApplicationController
  def index
    @board = SudokuBuilder.create.hard.to_a.flatten
  end

  def new
    @player_1_start = true
    @player_2_start = false
  end

  def create_challenge
    session[:user_name] ||= params[:user_name_input].titleize
    @user_name        = session[:user_name]
    @difficulty_level = params[:difficulty_level]
    @match            = create_new_match(difficulty: @difficulty_level.to_s, player_1_name: @user_name)
    @challenge_url    = join_match_url(match_key: @match.match_key)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('new_challenge_container', partial: 'home/waiting_for_challenger')
        ]
      end
    end
  end

  def join_match
    @player_1_start = false
    @player_2_start = true

    match = Match.find_by!(match_key: params[:match_key])
    @player_1_name = match.player_1_name
    @match_key     = match.match_key
    @difficulty_level = match.difficulty_level

    puts "Player 2 looking to join #{@difficulty_level} match(#{@match_key}) against #{@player_1_name}"
    render 'new'
  end

  def accept_challenge
    session[:user_name] ||= params[:user_name_input].titleize
    @user_name = session[:user_name]

    match = Match.find_by!(match_key: params[:match_key])
    match.player_2_name = @user_name
    match.save!

    player_2_game = match.games.create!(player_number: :player_2, player_name: match.player_2_name, uuid: SecureRandom.uuid)

    @board = match.starting_board

    game_1_html = render_to_string("home/_game", layout: false, locals: {board: @board, match_key: match.match_key, game_uuid: match.player_1_game.uuid})
    game_2_html = render_to_string("home/_game", layout: false, locals: {board: @board, match_key: match.match_key, game_uuid: player_2_game.uuid})

    match.set_start_time!

    puts "Player 2 (#{@user_name}) accepting challenge for match(#{match.match_key}) against Player 1 (#{match.player_1_game.player_name})"
    Turbo::StreamsChannel.broadcast_update_to(match.match_key, target: 'waiting_for_challenger_container', html: game_1_html)
    Turbo::StreamsChannel.broadcast_update_to(match.match_key, target: 'player_2_accept_challenge_container', html: game_2_html)
  end

  private

  def create_new_match(difficulty:, player_1_name:)
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
    starting_board = board.poke(difficulty_level).to_a.flatten
    match_key      = SecureRandom.uuid
    match          = Match.create!(starting_board: starting_board, solution: solution, match_key: match_key, player_1_name: player_1_name, difficulty_level: difficulty)

    match.games.create!(player_number: :player_1, player_name: player_1_name, uuid: SecureRandom.uuid)

    match
  end
end
