class Category < ApplicationRecord
  belongs_to :user
  has_many :lectures
  has_many :quizzes

  validates :title, presence: true, length: { maximum: 100 }
  validates :title, uniqueness: { scope: :user_id, message: "existe déjà" }
end
