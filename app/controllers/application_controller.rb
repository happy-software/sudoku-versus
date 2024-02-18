class ApplicationController < ActionController::Base
  # TODO: Add a global before_action to set session
  before_action :track_event

  def track_event
    # TODO: Track session within event
    ahoy.track action_name
  end
end
