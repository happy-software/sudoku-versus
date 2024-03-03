# require 'rack-attack'

# Blacklist bots looking for common entry points and vulnerabilities
Rack::Attack.blocklist('block common entry points and vulnerabilities') do |req|
  # Block requests targeting common entry points
  if req.path =~ %r{/wp-.*|/admin|/login.*|/admin/.*|/users.*|/script.*|/manager.*|/webui.*|/sitemap.*|/rest_route.*|/cgi.*|/server.*|/debug.*|/_.*|/ecp.*|/logon.*|/actuator.*}
    # Return true to block the request
    puts "[#{req.ip}] Blocking request searching for common entry points: #{req.path}"
    true
  end
end

Rack::Attack.blocklist("sensitive files scanning") do |req|
  # Block requests attempting to access sensitive files
  if req.path =~ /\.(git|env)/
    puts "[#{req.ip}] Blocking request attempting to access sensitive files: #{req.path}"
    true
  end
end
#
# Rack::Attack.blocklist("code injection attempts") do |req|
#   # Block requests with known exploit attempts (e.g., SQL injection, XSS)
#   # Modify the conditions according to your specific detection needs
#   if req.path =~ /(SELECT|UNION|INSERT|DELETE|UPDATE|CREATE|DROP|ALTER)/i || req.params.nil? || req.params.any? { |k, v| v =~ /(SELECT|UNION|INSERT|DELETE|UPDATE|CREATE|DROP|ALTER)/i }
#     puts "[#{req.ip}] Blocking request attempting code injection attacks: #{req.path}"
#     true
#   end
# end

Rack::Attack.blocklisted_response = lambda do |_env|
  # All blacklisted routes would 527 (no official error type associated with 527 according to wikipedia).
  [527, {}, ['Beep']]
end