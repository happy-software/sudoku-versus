class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  # TODO: Uncomment user if we ever add a User table, but for now the plan is to allow anonymous play
  #   belongs_to :user, optional: true

  # Lazily resolve and cache this visit's location from its stored IP using the
  # geocoder gem (remote IP lookup). Called from the admin dashboard so player
  # request paths never make external calls. Safe to call repeatedly: it no-ops
  # once `country` is populated, and geocoding failures are non-fatal.
  def geocode_from_ip!
    return self if country.present? || ip.blank?

    result = Geocoder.search(ip).first
    return self unless result

    update(
      country:   result.country,
      region:    result.state,
      city:      result.city,
      latitude:  result.latitude,
      longitude: result.longitude
    )
    self
  rescue StandardError
    self
  end

  # Human-readable "City, Region, Country" built from whatever location parts
  # are present. Returns nil when nothing has been resolved.
  def location_label
    parts = [city, region, country].map(&:presence).compact
    parts.join(", ").presence
  end
end
