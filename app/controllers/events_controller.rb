class EventsController < ApplicationController
  # Browser-only interactions (e.g. clicking "Copy to Clipboard" or hitting
  # Ctrl+C on the challenge link) never reach a normal controller action, so
  # they're invisible to our server-side analytics. The JS layer POSTs here to
  # record them as Ahoy events, keeping them in the same funnel as our tracked
  # page views. See ApplicationController#track_event.
  #
  # We skip the auto-tracker because it would record a useless "create" event;
  # instead we track the specific named event the client reports.
  skip_before_action :track_event, raise: false

  # The abandonment event is sent via navigator.sendBeacon during page unload,
  # which can't attach a CSRF token. Exempting this endpoint is safe: it only
  # inserts an allow-listed analytics row, so a forged request is harmless.
  skip_before_action :verify_authenticity_token, raise: false

  # Allow-list so the public endpoint can't be used to spray arbitrary event
  # names into our analytics.
  ALLOWED_EVENTS = %w[
    copy_button_clicked
    challenge_link_copied
    waiting_abandoned
  ].freeze

  def create
    name = params[:name].to_s
    return head(:unprocessable_entity) unless ALLOWED_EVENTS.include?(name)

    ahoy.track name, session_uuid: session[:session_uuid], match_key: params[:match_key]
    head :no_content
  end
end
