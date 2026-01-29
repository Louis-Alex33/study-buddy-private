module Subscribable
  extend ActiveSupport::Concern

  ADMIN_EMAILS = %w[la@mail.com].freeze

  PLAN_LIMITS = {
    "free" => {
      max_lectures: 3,
      max_file_size_mb: 5,
      max_messages_total: 10,
      max_flashcard_generations: 2,
      max_quiz_generations: 1,
      multiplayer_access: false
    },
    "pro" => {
      max_lectures: Float::INFINITY,
      max_file_size_mb: 10,
      max_messages_total: Float::INFINITY,
      max_flashcard_generations: Float::INFINITY,
      max_quiz_generations: Float::INFINITY,
      multiplayer_access: true
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
