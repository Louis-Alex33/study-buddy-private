class NotesController < ApplicationController
  before_action :set_note, only: [:destroy]
  before_action :authorize_note!, only: [:destroy]

  def create
    @lecture = Lecture.find(params[:lecture_id])
    @note = Note.new(note_params)
    @note.lecture = @lecture
    @note.user = current_user

    respond_to do |format|
      if @note.save
        format.turbo_stream
        format.html { redirect_to lecture_path(@note.lecture) }
      else
        format.html { render "lectures/show", status: :unprocessable_content }
      end
    end
  end

  def destroy
    lecture = @note.lecture
    @note.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to lecture_path(lecture), status: :see_other }
    end
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def authorize_note!
    unless @note.user == current_user
      redirect_to lectures_path, alert: "Accès non autorisé"
    end
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
