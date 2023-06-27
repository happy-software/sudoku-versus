class Match < ApplicationRecord
  has_many :games

  def set_start_time!(time=DateTime.now)
    self.started_at = time
    self.save!
  end

  def set_end_time!(time=DateTime.now)
    self.ended_at = time
    self.save!
  end

  def player_1_game
    games.where(player_number: :player_1, player_name: player_1_name).last
  end

  def player_2_game
    games.where(player_number: :player_2, player_name: player_2_name).last
  end

  def game_over_stats
    player_1_stats = player_1_game.stats
    player_2_stats = player_2_game.stats

    winner = [player_1_stats, player_2_stats].find { |stats| stats.fetch(:completed_board) }&.fetch(:player_number) || "N/A"

    {
      winner:                winner,
      player_1_name:         player_1_stats.fetch(:player_name),
      player_2_name:         player_2_stats.fetch(:player_name),
      player_1_accuracy:     player_1_stats.fetch(:accuracy).round(2),
      player_1_grade:        player_1_stats.fetch(:accuracy_grade),
      player_2_accuracy:     player_2_stats.fetch(:accuracy).round(2),
      player_2_grade:        player_2_stats.fetch(:accuracy_grade),
      player_1_squares_left: player_1_stats.fetch(:squares_left),
      player_2_squares_left: player_2_stats.fetch(:squares_left),
      total_time:            humanize((self.ended_at - self.started_at).to_i),
    }
  end

  private

  # Copied from StackOverflow post: https://stackoverflow.com/a/4136485
  def humanize(secs)
    [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)

        "#{n.to_i} #{name}" unless n.to_i==0
      end
    }.compact.reverse.join(' ')
  end
end
