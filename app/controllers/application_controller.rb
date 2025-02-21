class ApplicationController < ActionController::Base
  before_action :set_session_uuid
  before_action :track_event

  def set_session_uuid
    session[:session_uuid] ||= SecureRandom.uuid
  end

  def track_event
    puts "ALL HEADERS"
    puts request.headers.keys
    ahoy.track action_name, session_uuid: session[:session_uuid], **request.path_parameters, **request.headers.to_h.reject { |k,v| ['puma', 'action_dispatch', 'honeybadger', 'rack'].any? { |word| k.to_s.downcase.include?(word) } }
  end
end
