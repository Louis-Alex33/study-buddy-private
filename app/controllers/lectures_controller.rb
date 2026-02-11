class LecturesController < ApplicationController
  before_action :check_lecture_limit, only: [:create]
  before_action :set_lecture, only: [:show, :edit, :update, :destroy, :re_analyze, :download_resume]
  before_action :authorize_lecture!, only: [:show, :edit, :update, :destroy, :re_analyze, :download_resume]

  def index
    @lectures = current_user.lectures.includes(:category, :flashcards, :messages, :notes)
    @categories = current_user.categories.distinct
    @quizzes = Quiz.joins(:challenges).where(challenges: { user_id: current_user.id })

    if params[:search].present?
      @lectures = @lectures.where("title ILIKE :search OR resume ILIKE :search", search: "%#{params[:search]}%")
    elsif params[:query].present?
      @lectures = @lectures.joins(:category).where(categories: { title: params[:query] })
    end
  end

  def show
    @note = Note.new
  end

  def new
    @lecture = Lecture.new
  end

  def create
    @lecture = Lecture.new(lecture_params)
    @lecture.user = current_user

    # Handle new category creation
    if params[:new_category_title].present?
      category = current_user.categories.find_or_create_by(title: params[:new_category_title].strip)
      @lecture.category = category
    end

    if @lecture.save
      current_user.check_and_award_badges!
      redirect_to lecture_path(@lecture), notice: t("controllers.lectures.created")
    else
      @categories = current_user.categories.order(:title)
      render "pages/home", status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @lecture.update(lecture_params)
      redirect_to lecture_path(@lecture), notice: t("controllers.lectures.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @lecture.destroy
    redirect_to lectures_path, notice: t("controllers.lectures.destroyed")
  end

  def re_analyze
    LectureAnalyzerService.new(@lecture).call
    redirect_to lecture_path(@lecture), notice: t("controllers.lectures.re_analyzed")
  end

  def download_resume
    unless @lecture.resume.present?
      redirect_to lecture_path(@lecture), alert: t("controllers.lectures.no_resume")
      return
    end

    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: "lectures/resume_pdf",
        layout: "pdf",
        formats: [:html]
      ),
      encoding: "UTF-8",
      page_size: "A4",
      margin: { top: 20, bottom: 20, left: 20, right: 20 }
    )

    send_data pdf,
      filename: "#{@lecture.title.parameterize}-fiche-de-cours.pdf",
      type: "application/pdf",
      disposition: "attachment"
  end

  private

  def set_lecture
    @lecture = Lecture.find(params[:id])
  end

  def authorize_lecture!
    unless @lecture.user == current_user
      redirect_to lectures_path, alert: t("controllers.shared.unauthorized")
    end
  end

  def check_lecture_limit
    enforce_lecture_limit!
  end

  def lecture_params
    params.require(:lecture).permit(:title, :resume, :category_id, :document)
  end
end
