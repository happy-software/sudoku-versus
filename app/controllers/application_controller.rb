class ApplicationController < ActionController::Base
  before_action :set_session_uuid
  before_action :track_event

  def set_session_uuid
    session[:session_uuid] ||= SecureRandom.uuid
  end

  def track_event
    headers = request.headers.to_h.reject { |k,v| ['puma', 'action_dispatch', 'honeybadger', 'rack', 'action_controller'].any? { |word| k.to_s.downcase.include?(word) } }
    ahoy.track action_name, session_uuid: session[:session_uuid], **request.path_parameters, **headers
  end
end
