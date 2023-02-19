class HomeController < ApplicationController
  def index
    @board = SudokuBuilder.create.hard.to_a.flatten
  end
end
