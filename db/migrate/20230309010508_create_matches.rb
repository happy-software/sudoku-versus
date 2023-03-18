class CreateMatches < ActiveRecord::Migration[7.0]
  def change
    create_table :matches do |t|
      t.jsonb :solution
      t.jsonb :starting_board
      t.string :match_key

      t.timestamps
    end
  end
end
