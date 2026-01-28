class Lecture < ApplicationRecord
  has_one_attached :document

  belongs_to :user
  belongs_to :category
  has_many :flashcards, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :notes

  validates :title, presence: true
  validates :category, presence: true

  validate :document_presence
  validate :file_size_limit

  after_commit :analyze_document, on: :create

  def max_file_size_mb
    user&.max_file_size_mb || 5
  end

  def document_presence
    errors.add(:document, "must be attached") unless document.attached?
  end

  def file_size_limit
    if document.attached? && document.byte_size > max_file_size_mb.megabytes
      errors.add(:document, "La taille du fichier doit etre inferieure a #{max_file_size_mb}Mo")
    end
  end

  private

  def analyze_document
    LectureAnalyzerService.new(self).call
  end
end
