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
    match = create_new_match(difficulty: @difficulty_level.to_s, player_1_name: @user_name)
    @challenge_url = join_match_url(match_key: match.match_key)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('new_challenge_container', partial: 'home/waiting_for_challenger')
        ]
      end
    end
  end

  def waiting_for_challenger
    @challenge_creator_name = params[:match_uuid] # TODO: Update this stubbed value
  end

  def join_match
    @player_1_start = false
    @player_2_start = true

    match = Match.find_by!(match_key: params[:match_key])
    @player_1_name = match.player_1_name
    @match_key     = match.match_key
    @difficulty_level = match.difficulty_level
    render 'new'
  end

  def accept_challenge
    session[:user_name] ||= params[:user_name_input].titleize
    @user_name = session[:user_name]

    match = Match.find_by!(match_key: params[:match_key])
    match.player_2_name = @user_name
    match.save!

    @board = match.starting_board

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace('new_challenge_container', partial: 'home/board')
        ]
      end
      # format.turbo_stream { render turbo_stream: turbo_stream.replace('players_form', partial: 'new_player') }

    end
  end

  private

  def create_new_match(difficulty:, player_1_name:)
    if difficulty.to_s.downcase == 'easy'
      game = SudokuBuilder.create.easy
    elsif difficulty.to_s.downcase == 'medium'
      game = SudokuBuilder.create.medium
    elsif difficulty.to_s.downcase == 'hard'
      game = SudokuBuilder.create.hard
    elsif difficulty.to_s.downcase == 'very_hard'
      game = SudokuBuilder.create.poke(55)
    else
      ArgumentError.new("Given difficulty level: (#{difficulty}) is not recognized! Possible Options: (Easy, Medium, Hard, Very Hard)")
    end

    starting_board = game.to_a.flatten
    solution       = game.solve.to_a.flatten
    match_key      = SecureRandom.uuid
    Match.create!(starting_board: starting_board, solution: solution, match_key: match_key, player_1_name: player_1_name, difficulty_level: difficulty)
  end
end
