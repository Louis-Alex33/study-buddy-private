class AiChatJob < ApplicationJob
  queue_as :default

  def perform(lecture, user, message, assistant_message)
    AiChatService.new(lecture, user).stream_response(message, assistant_message)
  end
end
