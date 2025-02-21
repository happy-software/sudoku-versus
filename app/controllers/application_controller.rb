class ApplicationController < ActionController::Base
  before_action :set_session_uuid
  before_action :track_event

  def set_session_uuid
    session[:session_uuid] ||= SecureRandom.uuid
  end

  def track_event
    ahoy.track action_name, session_uuid: session[:session_uuid], **request.path_parameters, **request.headers.to_h
  end
end
