if Rails.env.production?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    puts "ENV['INPUT_CHECKER_URL'] is: #{ENV["INPUT_CHECKER_URL"].inspect}"
    host            = URI(ENV["INPUT_CHECKER_URL"]).host
    www_version     = host.starts_with?("www.") ? "https://#{host}" : "https://www.#{host}"
    non_www_version = www_version.sub("www.", "")

    allow do
      origins www_version, non_www_version

      resource '*',
               headers: :any,
               methods: [:get, :post, :put, :patch, :delete, :options, :head],
               credentials: true
    end
  end
end
