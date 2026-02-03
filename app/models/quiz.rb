class Quiz < ApplicationRecord
  belongs_to :category
  belongs_to :lecture, optional: true
  has_many :questions, dependent: :destroy
  has_many :attempts, dependent: :destroy
  has_many :challenges, dependent: :destroy
  has_many :quiz_bookmarks, dependent: :destroy
  has_many :bookmarked_by_users, through: :quiz_bookmarks, source: :user

  validates :title, presence: true
  validates :level, presence: true, inclusion: { in: 1..5 }
  validates :status, presence: true, inclusion: { in: %w[public shared] }

  scope :by_difficulty, -> { order(:level) }
end
