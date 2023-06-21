class Game < ApplicationRecord
  belongs_to :match

  # Records all the selections the player has made.
  # @param [Integer] selected_value
  # @param [Integer] selected_cell
  # @param [Boolean] is_correct
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

  # The current board with all the correct moves
  # the player has played up until now.
  # @return [Array]
  def current_board
    board               = self.match.starting_board.dup
    correct_submissions = (self.submissions || []).select { |s| s.fetch('is_correct') }
    correct_submissions.each do |submission|
      board[submission.fetch('selected_cell').to_i] = submission.fetch('selected_value').to_i
    end

    board
  end

  # Returns numbers that haven't been completed yet.
  # i.e. If a number hasn't been correctly placed in all
  # nine of it's cells, it's considered to be remaining.
  def remaining_numbers
    (1..9).to_a.select do |number|
      current_board.count(number) < 9
    end
  end

  def game_over?
    self.current_board.none?(nil)
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
      squares_left:      self.current_board.count(nil),
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
      squares_left:      self.current_board.count(nil),
    }
  end
end
