class HomeController < ApplicationController
  def index
    @board = SudokuBuilder.create.hard.to_a.flatten
    # @solved = [[[2, 5, 7], [9, 1, 6], [3, 8, 4]],
    #            [[4, 8, 1], [3, 5, 2], [9, 6, 7]],
    #            [[3, 6, 9], [4, 7, 8], [5, 1, 2]],
    #            [[1, 2, 3], [8, 9, 5], [7, 4, 6]],
    #            [[5, 7, 8], [6, 3, 4], [1, 2, 9]],
    #            [[9, 4, 6], [1, 2, 7], [8, 5, 3]],
    #            [[6, 9, 4], [7, 8, 1], [2, 3, 5]],
    #            [[8, 3, 2], [5, 4, 9], [6, 7, 1]],
    #            [[7, 1, 5], [2, 6, 3], [4, 9, 8]]].flatten
    #
    # @board = [[[2, 5, nil], [nil, nil, nil], [nil, 8, nil]],
    #           [[4, 8, 1], [3, 5, nil], [nil, 6, 7]],
    #           [[3, nil, nil], [4, 7, nil], [5, nil, nil]],
    #           [[nil, 2, nil], [nil, 9, nil], [nil, 4, nil]],
    #           [[5, 7, 8], [6, nil, nil], [1, nil, 9]],
    #           [[nil, nil, 6], [nil, 2, 7], [8, nil, nil]],
    #           [[nil, 9, nil], [nil, nil, 1], [nil, nil, 5]],
    #           [[nil, nil, 2], [5, 4, 9], [nil, 7, nil]],
    #           [[nil, 1, 5], [2, 6, nil], [nil, nil, nil]]].flatten
  end

  def new
  end

  def create_challenge
    challenge_creator_name = params[:userNameInput]
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('new_challenge_container', partial: 'home/waiting_for_challenger', locals: {challenge_creator_name: challenge_creator_name})
        ]
      end
    end
  end

  def waiting_for_challenger
    @challenge_creator_name = params[:match_uuid] # TODO: Update this stubbed value
  end
end
