class MessagesController < ApplicationController
  before_action :set_lecture
  before_action :check_message_limit, only: [:create]
  before_action -> { enforce_rate_limit!(:ai_message, max_per_minute: 10) }, only: [:create]

  def create
    @message = @lecture.messages.new(message_params)
    @message.role = "user"
    @message.user = current_user

    if @message.save
      @assistant_message = @lecture.messages.create!(
        role: "assistant",
        content: "",
        user: current_user
      )

      # Broadcaster les messages via Turbo Stream
      Turbo::StreamsChannel.broadcast_append_to(
        @lecture,
        target: "chat-messages",
        partial: "messages/message",
        locals: { message: @message }
      )

      Turbo::StreamsChannel.broadcast_append_to(
        @lecture,
        target: "chat-messages",
        partial: "messages/message",
        locals: { message: @assistant_message }
      )

      # Streaming IA via job asynchrone (évite le timeout Heroku 30s)
      AiChatJob.perform_later(@lecture, current_user, @message, @assistant_message)

      respond_to do |format|
        format.turbo_stream { head :ok }
        format.html { redirect_to lecture_path(@lecture), notice: t("controllers.messages.sent") }
      end
    else
      respond_to do |format|
        format.html { redirect_to lecture_path(@lecture), alert: t("controllers.messages.send_error") }
      end
    end
  end

  private

  def check_message_limit
    enforce_message_limit!
  end

  def set_lecture
    @lecture = current_user.lectures.find(params[:lecture_id])
  end

  def message_params
    params.require(:message).permit(:content, :file)
  end
end
