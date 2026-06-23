namespace :dash do
  desc "Geocode Ahoy visits that have an IP but no resolved country (admin dashboard locations)"
  task backfill_geocodes: :environment do
    scope = Ahoy::Visit.where(country: [nil, ""]).where.not(ip: [nil, ""])
    total = scope.count
    puts "Geocoding #{total} visit(s) with an IP but no country..."

    done = 0
    scope.find_each do |visit|
      visit.geocode_from_ip!
      done += 1
      print "\rProcessed #{done}/#{total}" if (done % 10).zero?
      # Be gentle with the remote IP lookup service's rate limits.
      sleep 0.5
    end

    puts "\nDone. #{Ahoy::Visit.where.not(country: [nil, ""]).count} visit(s) now have a location."
  end
end
