class Rack::Attack
  # Use in-memory store (resets on dyno restart, acceptable for single-dyno Heroku)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # --- Throttles ---

  # Global: 300 requests per 5 minutes per IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Login: 5 attempts per 20 seconds per IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.path == "/users/sign_in" && req.post? && req.ip
  end

  # AI generation endpoints: 5 per minute per user
  throttle("ai_generation/user", limit: 5, period: 1.minute) do |req|
    if req.post? && %w[/lectures /flashcards /quizzes].any? { |p| req.path.include?(p) }
      req.env["warden"]&.user&.id
    end
  end

  # AI messages: 10 per minute per user
  throttle("ai_messages/user", limit: 10, period: 1.minute) do |req|
    if req.post? && req.path.include?("/messages")
      req.env["warden"]&.user&.id
    end
  end

  # Custom throttle response
  self.throttled_responder = lambda do |_env|
    [429, { "Content-Type" => "text/html" }, ["Trop de requêtes. Réessaie dans quelques instants."]]
  end
end
