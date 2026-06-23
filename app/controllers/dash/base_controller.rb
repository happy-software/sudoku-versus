module Dash
  # Base controller for the hidden admin dashboard. All dash controllers inherit
  # from this so authentication and layout are enforced in one place.
  #
  # Access is gated by HTTP Basic Auth using the ADMIN_USERNAME / ADMIN_PASSWORD
  # environment variables. If either is unset, access is denied (the dashboard is
  # never open by accident).
  class BaseController < ApplicationController
    # Admin page views are not app usage; don't record them as Ahoy events.
    skip_before_action :track_event, raise: false

    before_action :authenticate_admin!

    layout "dash"

    private

    def authenticate_admin!
      authenticate_or_request_with_http_basic("SudokuVersus Admin") do |username, password|
        expected_user = ENV["ADMIN_USERNAME"].to_s
        expected_pass = ENV["ADMIN_PASSWORD"].to_s

        next false if expected_user.empty? || expected_pass.empty?

        # Non-short-circuiting `&` so the comparison time doesn't leak which of
        # the two credentials was wrong.
        ActiveSupport::SecurityUtils.secure_compare(username.to_s, expected_user) &
          ActiveSupport::SecurityUtils.secure_compare(password.to_s, expected_pass)
      end
    end
  end
end
