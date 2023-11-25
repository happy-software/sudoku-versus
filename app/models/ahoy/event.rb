class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods

  self.table_name = "ahoy_events"

  belongs_to :visit
  # TODO: Uncomment user if we ever add a User table, but for now the plan is to allow anonymous play
  #   belongs_to :user, optional: true
end
