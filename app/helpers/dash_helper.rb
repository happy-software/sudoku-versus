module DashHelper
  # Formats a duration in seconds as e.g. "3 minutes 12 seconds".
  # Mirrors the humanize helper used in Match#game_over_stats.
  def humanize_duration(secs)
    return "—" if secs.nil?

    secs = secs.to_i
    [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map do |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}" unless n.to_i.zero?
      end
    end.compact.reverse.join(" ").presence || "0 seconds"
  end

  # Consistent date/time formatting across the dashboard. Returns "—" for nil.
  def dash_time(time)
    return "—" if time.nil?

    time.strftime("%b %-d, %Y %-l:%M %p")
  end

  # Like dash_time but with seconds, since session events fire seconds apart and
  # their ordering is the whole point of the timeline.
  def event_time(time)
    return "—" if time.nil?

    time.strftime("%b %-d, %Y %-l:%M:%S %p")
  end

  # Human-friendly label for an Ahoy event name. Server-tracked events are named
  # after controller actions (e.g. "create_challenge"); our client-side events
  # use snake_case names too (e.g. "waiting_abandoned").
  def event_label(name)
    name.to_s.tr("_", " ").titleize
  end

  # Events we deliberately instrumented to understand match abandonment. These
  # get a colored badge so they stand out from routine page-view tracking.
  EVENT_BADGES = {
    "copy_button_clicked"   => "bg-success",
    "challenge_link_copied" => "bg-success",
    "waiting_abandoned"     => "bg-danger",
  }.freeze

  def event_badge_class(name)
    EVENT_BADGES[name.to_s]
  end

  # Whether an event belongs to the match being viewed, so the timeline can flag
  # on-topic events amid a session that may span several matches. Matches on the
  # match_key our client events carry, or the game/id path params the
  # server-tracked game actions record.
  def event_for_match?(event, match, game)
    props = event.properties || {}
    props["match_key"] == match.match_key ||
      props["id"].to_s == game.uuid.to_s ||
      props["game_id"].to_s == game.uuid.to_s
  end

  # Bootstrap badge describing a match's lifecycle state.
  def match_status_badge(match)
    if match.ended_at.present?
      tag.span("Completed", class: "badge bg-success")
    elsif match.started_at.present?
      tag.span("In progress", class: "badge bg-warning text-dark")
    else
      tag.span("Not started", class: "badge bg-secondary")
    end
  end
end
