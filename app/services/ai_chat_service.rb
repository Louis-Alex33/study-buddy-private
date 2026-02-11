class AiChatService
  AI_MODEL = "gemini-2.0-flash"
  FALLBACK_MODEL = "gpt-4o"

  def initialize(lecture, current_user)
    @lecture = lecture
    @current_user = current_user
  end

  def stream_response(message, assistant_message)
    chat = RubyLLM.chat(model: AI_MODEL)
    load_conversation_history(chat, exclude_id: assistant_message.id)

    if message.file.attached?
      content = process_file(chat, message)
      assistant_message.update(content: content)
      broadcast_replace(assistant_message)
    else
      stream_text_response(chat, message, assistant_message)
    end
  rescue => e
    Rails.logger.error "Streaming error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    assistant_message.update(content: "Erreur lors de la génération de la réponse: #{e.message}")
    broadcast_replace(assistant_message)
  end

  private

  def load_conversation_history(chat, exclude_id: nil)
    messages = @lecture.messages.order(:created_at)
    messages = messages.where.not(id: exclude_id) if exclude_id
    messages.each do |msg|
      next if msg.content.blank?
      chat.add_message(role: msg.role, content: msg.content)
    end
  end

  def stream_text_response(chat, message, assistant_message)
    accumulated_content = ""
    chunk_counter = 0
    last_update_time = Time.now

    chat.with_instructions(instructions).ask(message.content) do |chunk|
      chunk_content = extract_chunk_content(chunk)
      next if chunk_content.nil? || chunk_content.empty?

      accumulated_content += chunk_content
      chunk_counter += 1

      if chunk_counter >= 3 || (Time.now - last_update_time) >= 0.1
        assistant_message.update(content: accumulated_content)
        broadcast_replace(assistant_message)
        chunk_counter = 0
        last_update_time = Time.now
      end
    end

    assistant_message.update(content: accumulated_content)
    broadcast_replace(assistant_message)
  end

  def process_file(chat, message)
    if message.file.content_type == "application/pdf"
      process_pdf(message)
    elsif message.file.image?
      process_image(chat, message)
    else
      chat.with_instructions(instructions).ask(message.content).content
    end
  end

  def process_pdf(message)
    chat = RubyLLM.chat(model: AI_MODEL)
    load_conversation_history(chat)
    chat.with_instructions(instructions)
    chat.ask(message.content, with: { pdf: message.file.url }).content
  rescue => e
    raise e unless quota_error?(e)

    Rails.logger.warn "Gemini quota exceeded, falling back to #{FALLBACK_MODEL}: #{e.message}"
    chat = RubyLLM.chat(model: FALLBACK_MODEL)
    load_conversation_history(chat)
    chat.with_instructions(instructions)
    chat.ask(message.content, with: { pdf: message.file.url }).content
  end

  def process_image(chat, message)
    chat = RubyLLM.chat(model: AI_MODEL)
    load_conversation_history(chat)
    chat.with_instructions(instructions)
    chat.ask(message.content, with: { image: message.file.url }).content
  end

  def instructions
    "Tu es un assistant pédagogique intelligent spécialisé dans l'aide aux études.
    Tu aides les étudiants à comprendre le contenu de leurs cours (la lecture : #{@lecture.title}).

    CONTEXTE DU COURS :
    #{@lecture.resume.present? ? "Résumé du document : #{@lecture.resume}" : "Aucun résumé disponible pour ce cours."}

    TES RESPONSABILITÉS :
    - Répondre DIRECTEMENT aux questions posées par l'étudiant
    - Expliquer les concepts difficiles avec des exemples concrets
    - Aider à la compréhension et à la mémorisation
    - Proposer des exercices ou des moyens mnémotechniques si demandé
    - Rester factuel et basé sur le contenu du cours

    CONTRAINTES :
    - Réponds toujours en français
    - Réponds DIRECTEMENT à la question posée, ne crée PAS de sommaire ou de table des matières
    - Sois concis mais complet
    - Si tu ne connais pas la réponse basée sur le cours, dis-le honnêtement
    - N'invente jamais d'informations
    - Utilise un ton amical et encourageant
    - Réponds en format markdown"
  end

  def extract_chunk_content(chunk)
    if chunk.is_a?(String)
      chunk
    elsif chunk.respond_to?(:content)
      chunk.content.to_s
    else
      chunk.to_s
    end
  end

  def quota_error?(error)
    error.message.include?("429") ||
    error.message.include?("Resource exhausted") ||
    error.message.include?("quota") ||
    error.message.include?("rate limit")
  end

  def broadcast_replace(assistant_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @lecture,
      target: "message_#{assistant_message.id}",
      partial: "messages/message",
      locals: { message: assistant_message }
    )
  end
end
