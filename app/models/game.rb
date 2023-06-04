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
end
