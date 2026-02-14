class FlashcardGenerateJob < ApplicationJob
  queue_as :default

  def perform(lecture, user)
    ruby_llm_chat = RubyLLM.chat(model: "gemini-2.0-flash")

    prompt = <<~PROMPT
      Génère 10 questions à partir de cette lecture:

      Titre: #{lecture.title}
      Résumé: #{lecture.resume}

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
      lecture.flashcards.create(
        content: questions_data.to_json,
        expected_answer: "Quiz de 10 questions"
      )
      user.increment!(:flashcard_generations_count)
    end
  rescue => e
    Rails.logger.error "FlashcardGenerateJob error for lecture #{lecture.id}: #{e.message}"
  end
end
