class Message < ApplicationRecord
  belongs_to :lecture
  belongs_to :user
  has_one_attached :file

  validates :role, presence: true
  validate :user_message_limit

  def user_message_limit
    return unless role == "user"

    max = user&.plan_limit(:max_messages_total) || 10
    return if max == Float::INFINITY

    current_count = Message.where(role: "user", user: user).count
    if current_count >= max
      errors.add(:content, "Tu as atteint la limite de #{max} messages au total. Passe à Studigo Pro pour un accès illimité.")
    end
  end
end
