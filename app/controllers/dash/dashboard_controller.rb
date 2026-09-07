module Dash
  # Overview / landing page for the admin dashboard: high-level usage metrics.
  class DashboardController < BaseController
    def index
      @total_matches     = Match.count
      @completed_matches = Match.where.not(ended_at: nil).count
      @completion_rate   = @total_matches.zero? ? 0 : (@completed_matches.to_f / @total_matches * 100).round(1)

      @matches_24h = Match.where("created_at >= ?", 24.hours.ago)
      @matches_7d  = Match.where("created_at >= ?", 7.days.ago)
      @matches_30d = Match.where("created_at >= ?", 30.days.ago)
      @matches_6m  = Match.where("created_at >= ?", 6.months.ago)

      @matches_24h_count = @matches_24h.count
      @matches_7d_count  = @matches_7d.count
      @matches_30d_count = @matches_30d.count
      @matches_6m_count = @matches_6m.count

      @matches_24h_completed = @matches_24h.where.not(ended_at: nil).count
      @matches_7d_completed  = @matches_7d.where.not(ended_at: nil).count
      @matches_30d_completed = @matches_30d.where.not(ended_at: nil).count
      @matches_6m_completed = @matches_6m.where.not(ended_at: nil).count

      @unique_visitors = Ahoy::Visit.distinct.count(:visitor_token)
      @total_visits    = Ahoy::Visit.count

      @difficulty_breakdown = Match.group(:difficulty_level).count.sort_by { |_level, count| -count }

      # Locations resolved so far (visits we've already geocoded via the dashboard
      # or the backfill task). Visits without a country yet are grouped as Unknown.
      @top_countries = Ahoy::Visit.where.not(country: [nil, ""])
                                  .group(:country).count
                                  .sort_by { |_country, count| -count }
                                  .first(10)

      @recent_matches = Match.order(created_at: :desc).limit(10)
    end
  end
end
