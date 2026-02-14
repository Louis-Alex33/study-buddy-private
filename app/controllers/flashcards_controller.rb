class FlashcardsController < ApplicationController
  before_action :set_lecture, only: [:new, :create]
  before_action :set_flashcard, only: [:show, :update_progress, :destroy]
  before_action :authorize_flashcard!, only: [:destroy]
  before_action :check_flashcard_limit, only: [:create]
  before_action -> { enforce_rate_limit!(:ai_flashcard, max_per_minute: 3) }, only: [:create]

  def new
  end

  def create
    FlashcardGenerateJob.perform_later(@lecture, current_user)
    redirect_to lecture_path(@lecture, anchor: "flashcards-section"), notice: "Les flashcards sont en cours de génération. Rafraîchis la page dans quelques secondes."
  end

  def show
    @completion = current_user.flashcard_completions.find_or_initialize_by(flashcard: @flashcard)
    @progress = @completion.status.to_i
  end

  VALID_PROGRESS = %w[0 10 20 30 40 50 60 70 80 90 100].freeze

  def update_progress
    unless VALID_PROGRESS.include?(params[:progress].to_s)
      head :unprocessable_entity
      return
    end

    completion = current_user.flashcard_completions.find_or_initialize_by(flashcard: @flashcard)
    completion.status = params[:progress]
    completion.save
    current_user.check_and_award_badges!
    head :ok
  end

  def destroy
    lecture = @flashcard.lecture
    @flashcard.destroy
    redirect_to lecture_path(lecture, anchor: "flashcards-section"), notice: t("controllers.flashcards.destroyed")
  end

  private

  def set_flashcard
    @flashcard = Flashcard.find(params[:id])
  end

  def authorize_flashcard!
    unless @flashcard.lecture.user == current_user
      redirect_to lectures_path, alert: t("controllers.shared.unauthorized")
    end
  end

  def check_flashcard_limit
    enforce_flashcard_generation_limit!
  end

  def set_lecture
    @lecture = current_user.lectures.find(params[:lecture_id])
  end

  def generate_flashcards_with_ai
    ruby_llm_chat = RubyLLM.chat(model: "gemini-2.0-flash")

    prompt = <<~PROMPT
      Génère 10 questions à partir de cette lecture:

      Titre: #{@lecture.title}
      Résumé: #{@lecture.resume}

      Format ta réponse EXACTEMENT comme ceci (une question par bloc):

      Q: [question ici]
      R: [réponse ici]
      ---

      Assure-toi de bien séparer chaque question par "---"
    PROMPT

    response = ruby_llm_chat.ask(prompt)
    flashcards_text = response.content
    question_blocks = flashcards_text.split("---").map(&:strip).reject(&:empty?)
    questions_data = []

    question_blocks.each do |block|
      lines = block.split("\n").map(&:strip)
      question_line = lines.find { |l| l.start_with?("Q:") }
      answer_line = lines.find { |l| l.start_with?("R:") }

      if question_line && answer_line
        questions_data << {
          question: question_line.sub("Q:", "").strip,
          answer: answer_line.sub("R:", "").strip
        }
      end
    end
    if questions_data.any?
      flashcard = @lecture.flashcards.create(
        content: questions_data.to_json,
        expected_answer: "Quiz de 10 questions"
      )
      [flashcard]
    else
      []
    end
  end
end
