class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  # TODO: Uncomment user if we ever add a User table, but for now the plan is to allow anonymous play
  #   belongs_to :user, optional: true
end
