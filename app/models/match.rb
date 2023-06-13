class Match < ApplicationRecord
  has_many :games

  def player_1_game
    games.where(player_number: :player_1, player_name: player_1_name).first
  end

  def player_2_game
    games.where(player_number: :player_2, player_name: player_2_name).first
  end

  def game_over_stats
    player_1_stats = player_1_game.stats
    player_2_stats = player_2_game.stats

    winner = [player_1_stats, player_2_stats].find { |stats| stats.fetch(:completed_board) }&.fetch(:player_number) || "N/A"

    {
      winner:            winner,
      player_1_name:     player_1_stats.fetch(:player_name),
      player_2_name:     player_2_stats.fetch(:player_name),
      player_1_time:     player_1_stats.fetch(:total_time),
      player_2_time:     player_2_stats.fetch(:total_time),
      player_1_accuracy: player_1_stats.fetch(:accuracy).round(2),
      player_1_grade:    player_1_stats.fetch(:accuracy_grade),
      player_2_accuracy: player_2_stats.fetch(:accuracy).round(2),
      player_2_grade:    player_2_stats.fetch(:accuracy_grade),
    }
  end
end
