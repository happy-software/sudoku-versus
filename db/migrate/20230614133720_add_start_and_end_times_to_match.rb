class AddStartAndEndTimesToMatch < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :started_at, :datetime
    add_column :matches, :ended_at, :datetime
  end
end
