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
    accuracy_grade     = case accuracy
                         when 95..100
                           "A+ 🌟"
                         when 90...95
                           "A-"
                         when 80...90
                           "B"
                         when 70...80
                           "C"
                         when 60...70
                           "D"
                         when 0...60
                           "F 😱"
                         end

    {
      played_move_count: self.submissions.count,
      accuracy:          accuracy,
      accuracy_grade:    accuracy_grade,
      player_number:     self.player_number,
      player_name:       self.player_name,
      completed_board:   self.game_over?,
    }
  end

  private
  def empty_stats
    {
      played_move_count: 0,
      accuracy:          0,
      accuracy_grade:    "(X)",
      player_name:       self.player_name,
      player_number:     self.player_number,
      completed_board:   false,
    }
  end
end
