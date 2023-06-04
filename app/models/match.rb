class Match < ApplicationRecord
  has_many :games

  def player_1_game
    games.where(player_number: :player_1, player_name: player_1_name).first
  end

  def player_2_game
    games.where(player_number: :player_2, player_name: player_2_name).first
  end
end
