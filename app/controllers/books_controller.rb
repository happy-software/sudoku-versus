class BooksController < ApplicationController
  def index
    easy_difficulty      = (25..32).to_a.sample
    medium_difficulty    = (31..39).to_a.sample
    hard_difficulty      = (38..46).to_a.sample
    very_hard_difficulty = (55..65).to_a.sample

    easy_games      = 100.times.map { SudokuBuilder.create.poke(easy_difficulty).to_a.flatten }
    medium_games    = 100.times.map { SudokuBuilder.create.poke(medium_difficulty).to_a.flatten }
    hard_games      = 100.times.map { SudokuBuilder.create.poke(hard_difficulty).to_a.flatten }
    very_hard_games = 100.times.map { SudokuBuilder.create.poke(very_hard_difficulty).to_a.flatten }

    @sections = {
      easy_difficulty:      easy_games,
      medium_difficulty:    medium_games,
      hard_difficulty:      hard_games,
      very_hard_difficulty: very_hard_games,
    }

    render pdf: 'file_name', print_media_type: true, layout: "book", page_size: "A5"
  end
end
