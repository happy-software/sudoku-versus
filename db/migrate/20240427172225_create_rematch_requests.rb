class CreateRematchRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :rematch_requests do |t|
      t.references :challenger_game, null: false, foreign_key: { to_table: :games }
      t.references :challengee_game, null: false, foreign_key: { to_table: :games }
      t.references :match, null: false, foreign_key: true
      t.datetime :accepted_at

      t.timestamps
    end
  end
end
