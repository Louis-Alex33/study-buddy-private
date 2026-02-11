class Attempt < ApplicationRecord
  belongs_to :user
  belongs_to :quiz
  has_many :answers, dependent: :destroy

  scope :completed, -> { where(done: true) }
  scope :in_progress, -> { where(done: false) }

  def calculate_score
    return 0 if answers.empty?

    answers_by_question = answers.to_a.group_by(&:question_id)
    questions_with_options = quiz.questions.includes(:options).to_a

    correct_count = 0
    questions_with_options.each do |question|
      user_answers = answers_by_question[question.id] || []
      correct_ids = question.options.select(&:correct).map(&:id)

      if question.multiple_answers
        selected_ids = user_answers.map(&:option_id)
        correct_count += 1 if selected_ids.sort == correct_ids.sort
      else
        correct_count += 1 if user_answers.any? { |a| correct_ids.include?(a.option_id) }
      end
    end

    correct_count
  end

  def total_questions
    quiz.questions.count
  end

  def percentage_score
    return 0 if total_questions.zero?
    (score.to_f / total_questions * 100).round
  end
end
