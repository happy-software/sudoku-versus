# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_07_162646) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_id"
    t.string "player_name"
    t.string "player_number"
    t.uuid "session_uuid"
    t.jsonb "submissions"
    t.datetime "updated_at", null: false
    t.uuid "uuid"
    t.index ["match_id"], name: "index_games_on_match_id"
  end

  create_table "matches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "difficulty_level"
    t.datetime "ended_at"
    t.uuid "match_key"
    t.string "player_1_name"
    t.string "player_2_name"
    t.jsonb "solution"
    t.datetime "started_at"
    t.jsonb "starting_board"
    t.datetime "updated_at", null: false
  end

  create_table "rematch_requests", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "challengee_game_id", null: false
    t.bigint "challenger_game_id", null: false
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.datetime "updated_at", null: false
    t.index ["challengee_game_id"], name: "index_rematch_requests_on_challengee_game_id"
    t.index ["challenger_game_id"], name: "index_rematch_requests_on_challenger_game_id"
    t.index ["match_id"], name: "index_rematch_requests_on_match_id"
  end

  add_foreign_key "rematch_requests", "games", column: "challengee_game_id"
  add_foreign_key "rematch_requests", "games", column: "challenger_game_id"
  add_foreign_key "rematch_requests", "matches"
end
