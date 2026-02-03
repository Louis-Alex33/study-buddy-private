module Subscribable
  extend ActiveSupport::Concern

  ADMIN_EMAILS = %w[la@mail.com famille@studigo.fr].freeze

  PLAN_LIMITS = {
    "free" => {
      max_lectures: 3,
      max_file_size_mb: 5,
      max_messages_total: 10,
      max_flashcard_generations: 2,
      max_quiz_generations: 1,
      multiplayer_access: false,
      max_ips_per_day: 3
    },
    "pro" => {
      max_lectures: Float::INFINITY,
      max_file_size_mb: 10,
      max_messages_total: Float::INFINITY,
      max_flashcard_generations: Float::INFINITY,
      max_quiz_generations: Float::INFINITY,
      multiplayer_access: true,
      max_ips_per_day: 5
    }
  }.freeze

  included do
    validates :plan, inclusion: { in: %w[free pro] }
  end

  def admin?
    ADMIN_EMAILS.include?(email)
  end

  def pro?
    admin? || plan == "pro"
  end

  def free?
    !pro?
  end

  def plan_limit(key)
    effective_plan = pro? ? "pro" : plan
    PLAN_LIMITS.dig(effective_plan, key)
  end

  def can_create_lecture?
    pro? || lectures.count < plan_limit(:max_lectures)
  end

  def lectures_remaining
    return Float::INFINITY if pro?
    [plan_limit(:max_lectures) - lectures.count, 0].max
  end

  def max_file_size_mb
    plan_limit(:max_file_size_mb)
  end

  def can_send_message?
    pro? || total_user_messages_count < plan_limit(:max_messages_total)
  end

  def messages_remaining
    return Float::INFINITY if pro?
    [plan_limit(:max_messages_total) - total_user_messages_count, 0].max
  end

  def total_user_messages_count
    Message.where(role: "user", user: self).count
  end

  def can_generate_flashcards?
    pro? || flashcard_generations_count < plan_limit(:max_flashcard_generations)
  end

  def flashcard_generations_remaining
    return Float::INFINITY if pro?
    [plan_limit(:max_flashcard_generations) - flashcard_generations_count, 0].max
  end

  def can_generate_quiz?
    pro? || quiz_generations_count < plan_limit(:max_quiz_generations)
  end

  def quiz_generations_remaining
    return Float::INFINITY if pro?
    [plan_limit(:max_quiz_generations) - quiz_generations_count, 0].max
  end

  def has_multiplayer_access?
    pro?
  end

  def log_ip!(ip_address)
    return if ip_address.blank?

    # Only insert if this IP wasn't already logged in the last 24h
    unless user_ip_logs.where(ip_address: ip_address).where("created_at > ?", 24.hours.ago).exists?
      user_ip_logs.create!(ip_address: ip_address)
    end
  end

  def distinct_ips_last_24h
    user_ip_logs.where("created_at > ?", 24.hours.ago).distinct.count(:ip_address)
  end

  def ip_allowed?(ip_address)
    return true if ip_address.blank?
    return true if test_account?

    # If this IP is already known in the last 24h, it's always allowed
    return true if user_ip_logs.where(ip_address: ip_address).where("created_at > ?", 24.hours.ago).exists?

    # Otherwise, check if adding a new IP would exceed the limit
    distinct_ips_last_24h < plan_limit(:max_ips_per_day)
  end

  def test_account?
    email.match?(/\Atest\d+@studigo\.fr\z/)
  end

  def active_subscription
    payment_processor&.subscription
  end

  def sync_plan_from_subscription!
    sub = active_subscription
    if sub&.active?
      update!(plan: "pro")
    else
      update!(plan: "free")
    end
  end
end
