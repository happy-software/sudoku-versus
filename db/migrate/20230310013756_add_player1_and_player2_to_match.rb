class AddPlayer1AndPlayer2ToMatch < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :player_1_name, :string
    add_column :matches, :player_2_name, :string
  end
end
