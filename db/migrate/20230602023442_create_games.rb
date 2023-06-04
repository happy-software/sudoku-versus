class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.uuid :uuid
      t.string :player_number
      t.string :player_name
      t.jsonb :submissions
      t.references :match

      t.timestamps
    end
  end
end
