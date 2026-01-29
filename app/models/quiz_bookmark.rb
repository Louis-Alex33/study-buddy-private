class QuizBookmark < ApplicationRecord
  belongs_to :user
  belongs_to :quiz

  validates :quiz_id, uniqueness: { scope: :user_id, message: "déjà dans vos favoris" }
end
