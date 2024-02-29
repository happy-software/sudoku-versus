# require 'rack-attack'

# Blacklist bots looking for common entry points and vulnerabilities
Rack::Attack.blocklist('block common entry points and vulnerabilities') do |req|
  # Block requests targeting common entry points
  if req.path =~ %r{/wp-admin|/admin|/login|/admin/.*}
    # Return true to block the request
    puts "Blocking request searching for common entry points: #{req.path}"
    return true
  end

  # Block requests attempting to access sensitive files
  if req.path =~ /\.(git|env)/
    puts "Blocking request attempting to access sensitive files: #{req.path}"
    return true
  end

  # Block requests with known exploit attempts (e.g., SQL injection, XSS)
  # Modify the conditions according to your specific detection needs
  if req.path =~ /(SELECT|UNION|INSERT|DELETE|UPDATE|CREATE|DROP|ALTER)/i || req.params.any? { |k, v| v =~ /(SELECT|UNION|INSERT|DELETE|UPDATE|CREATE|DROP|ALTER)/i }
    puts "Blocking request attempting code injection attacks: #{req.path}"
    return true
  end
end