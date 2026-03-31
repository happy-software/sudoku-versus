module ApplicationHelper
  def self.poke(solution, difficulty)
    generator = SudokuGenerator.new(solution)
    board = generator.generate(difficulty)

    board
  end
end
