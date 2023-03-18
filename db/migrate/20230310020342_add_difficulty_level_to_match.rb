class AddDifficultyLevelToMatch < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :difficulty_level, :string
  end
end
