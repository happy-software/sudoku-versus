class ApplicationController < ActionController::Base
  before_action :track_event

  def track_event
    ahoy.track action_name
  end
end
