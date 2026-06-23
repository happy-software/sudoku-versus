class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods

  self.table_name = "ahoy_events"

  belongs_to :visit
  # TODO: Uncomment user if we ever add a User table, but for now the plan is to allow anonymous play
  #   belongs_to :user, optional: true

  # Every request is tracked with the player's session_uuid in `properties`
  # (see ApplicationController#track_event). Use the jsonb containment operator
  # `@>` so the existing GIN index on `properties` is used.
  scope :for_session, ->(uuid) { where("properties @> ?", { session_uuid: uuid }.to_json) }
end
