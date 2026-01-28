module Subscribable
  extend ActiveSupport::Concern

  PLAN_LIMITS = {
    "free" => {
      max_lectures: 3,
      max_file_size_mb: 5,
      max_messages_per_lecture: 5,
      max_flashcard_generations: 2,
      max_quiz_generations: 2,
      multiplayer_access: false
    },
    "pro" => {
      max_lectures: Float::INFINITY,
      max_file_size_mb: 10,
      max_messages_per_lecture: Float::INFINITY,
      max_flashcard_generations: Float::INFINITY,
      max_quiz_generations: Float::INFINITY,
      multiplayer_access: true
    }
  }.freeze

  included do
    validates :plan, inclusion: { in: %w[free pro] }
  end

  def pro?
    plan == "pro"
  end

  def free?
    plan == "free"
  end

  def plan_limit(key)
    PLAN_LIMITS.dig(plan, key)
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

  def can_send_message?(lecture)
    pro? || lecture.messages.where(role: "user", user: self).count < plan_limit(:max_messages_per_lecture)
  end

  def messages_remaining(lecture)
    return Float::INFINITY if pro?
    [plan_limit(:max_messages_per_lecture) - lecture.messages.where(role: "user", user: self).count, 0].max
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
