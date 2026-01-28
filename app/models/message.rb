class Message < ApplicationRecord
  belongs_to :lecture
  belongs_to :user
  has_one_attached :file

  validates :role, presence: true
  validate :user_message_limit

  def user_message_limit
    return unless role == "user"

    max = user&.plan_limit(:max_messages_per_lecture) || 5
    return if max == Float::INFINITY

    current_count = lecture.messages.where(role: "user", user: user).count
    if current_count >= max
      errors.add(:content, "Vous avez atteint la limite de #{max} messages pour ce cours. Passez a Studigo Pro pour un acces illimite.")
    end
  end
end
