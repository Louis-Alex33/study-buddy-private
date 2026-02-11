desc "Ping the app to prevent Heroku cold start"
task ping: :environment do
  require "net/http"
  url = ENV.fetch("APP_URL", "https://studigo-5605123477b4.herokuapp.com")
  uri = URI("#{url}/health")
  response = Net::HTTP.get_response(uri)
  puts "Ping #{uri} — #{response.code}"
end
