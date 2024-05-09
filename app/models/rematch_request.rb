class RematchRequest < ApplicationRecord
  belongs_to :challenger_game, class_name: "Game"
  belongs_to :challengee_game, class_name: "Game"
  belongs_to :match

  # TODO: Add reject! and rejected? helpers

  def accept!
    self.accepted_at = DateTime.now
    self.save!
  end

  def accepted?
    self.accepted_at?
  end
end
