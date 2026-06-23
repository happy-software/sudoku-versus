# Geocoding configuration for the admin dashboard.
#
# We resolve player locations from the IP addresses Ahoy already stores on each
# visit. Lookups go to a remote IP geolocation service (no local MaxMind DB), are
# performed lazily when viewing a match, and are cached onto the ahoy_visits row.
# See Ahoy::Visit#geocode_from_ip!.
Geocoder.configure(
  ip_lookup: :ipinfo_io,
  timeout:   5,
  units:     :km
)
