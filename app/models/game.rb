class Game < ApplicationRecord
  belongs_to :match

  def record_selection!(selected_value, selected_cell, is_correct)
    self.submissions ||= []
    self.submissions << {
      selected_value: selected_value,
      selected_cell:  selected_cell,
      is_correct:     is_correct,
      timestamp:      Time.now,
    }

    self.save!
  end

  def game_over?
    board               = self.match.starting_board
    submissions         = self.submissions || []
    correct_submissions = submissions.select { |s| s.fetch('is_correct') }

    correct_submissions.each do |submission|
      board[submission.fetch('selected_cell').to_i] = submission.fetch('selected_value')
    end

    board.none?(nil)
  end

  def stats
    self.submissions   ||= []
    return empty_stats if self.submissions.empty?

    sorted_submissions = self.submissions.sort_by { |s| s.fetch('timestamp').to_datetime }
    first_move_time    = sorted_submissions.first.fetch('timestamp').to_datetime
    last_move_time     = sorted_submissions.last.fetch('timestamp').to_datetime
    accuracy           = (self.submissions.select { |s| s.fetch('is_correct') }.count.to_f / self.submissions.count.to_f) * 100

    {
      played_move_count: self.submissions.count,
      accuracy:          accuracy,
      player_number:     self.player_number,
      player_name:       self.player_name,
      start_time:        first_move_time,
      end_time:          last_move_time,
      total_time:        humanize(last_move_time.to_i - first_move_time.to_i),
      completed_board:   self.game_over?,
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

  def empty_stats
    {
      played_move_count: 0,
      accuracy:          0,
      player_name:       self.player_name,
      player_number:     self.player_number,
      start_time:        nil,
      end_time:          nil,
      total_time:        "No moves played!",
      completed_board:   false,
    }
  end
end
