class Lecture < ApplicationRecord
  has_one_attached :document

  belongs_to :user
  belongs_to :category
  has_many :flashcards, dependent: :destroy
  has_many :quizzes, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :notes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :category, presence: true

  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    image/png image/jpeg image/jpg image/gif image/webp
    text/plain
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  validate :document_presence
  validate :file_size_limit
  validate :file_content_type

  after_commit :analyze_document, on: :create

  def max_file_size_mb
    user&.max_file_size_mb || 5
  end

  def document_presence
    errors.add(:document, "must be attached") unless document.attached?
  end

  def file_size_limit
    if document.attached? && document.byte_size > max_file_size_mb.megabytes
      errors.add(:document, "La taille du fichier doit être inférieure à #{max_file_size_mb}Mo")
    end
  end

  def file_content_type
    if document.attached? && !ALLOWED_CONTENT_TYPES.include?(document.content_type)
      errors.add(:document, "Type de fichier non autorisé. Formats acceptés : PDF, images (PNG, JPEG, GIF, WebP), texte, Word")
    end
  end

  private

  def analyze_document
    LectureAnalyzerService.new(self).call
  end
end
