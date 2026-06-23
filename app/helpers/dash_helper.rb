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
