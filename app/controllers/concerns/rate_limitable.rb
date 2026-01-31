module RateLimitable
  extend ActiveSupport::Concern

  private

  # Limite les requêtes IA par utilisateur (max par minute)
  def enforce_rate_limit!(action_key, max_per_minute: 5)
    cache_key = "rate_limit:#{current_user.id}:#{action_key}"
    count = Rails.cache.read(cache_key).to_i

    if count >= max_per_minute
      redirect_back fallback_location: lectures_path,
        alert: "Trop de requêtes. Patiente quelques instants avant de réessayer."
      return false
    end

    Rails.cache.write(cache_key, count + 1, expires_in: 1.minute)
    true
  end
end
