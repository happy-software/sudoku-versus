module Dash
  class MatchesController < BaseController
    PER_PAGE = 50

    def index
      @page    = [params[:page].to_i, 1].max
      @total   = Match.count
      @matches = Match.order(created_at: :desc)
                      .limit(PER_PAGE)
                      .offset((@page - 1) * PER_PAGE)
      @has_next = @page * PER_PAGE < @total
    end

    def show
      @match = Match.find(params[:id])

      # One row per game in the match (handles started/unstarted matches without
      # relying on Match#game_over_stats, which assumes both players + timing).
      @players = @match.games.order(:created_at).map do |game|
        visit = game.visit
        visit&.geocode_from_ip!

        { game: game, stats: game.stats, visit: visit }
      end

      @duration = if @match.started_at && @match.ended_at
                    @match.ended_at - @match.started_at
                  end
    end
  end
end
