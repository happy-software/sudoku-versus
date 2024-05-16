module ApplicationHelper
  def self.poke(solution, count)
    board = solution.deep_dup

    while(board.count(nil) < count)
      board[(0..80).to_a.sample] = nil
    end

    board
  end
end
