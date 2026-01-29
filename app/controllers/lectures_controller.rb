class LecturesController < ApplicationController
  before_action :check_lecture_limit, only: [:create]

  def index
    @lectures = current_user.lectures
    @categories = current_user.categories.distinct
    @quizzes = Quiz.all

    if params[:search].present?
      @lectures = @lectures.where("title ILIKE :search OR resume ILIKE :search", search: "%#{params[:search]}%")
    elsif params[:query].present?
      @lectures = @lectures.joins(:category).where(categories: { title: params[:query] })
    end
  end

  def show
    @lecture = Lecture.find(params[:id])
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
      redirect_to lecture_path(@lecture), notice: "Lecture créée avec succès"
    else
      @categories = Category.all
      render "pages/home", status: :unprocessable_content
    end
  end

  def edit
    @lecture = Lecture.find(params[:id])
  end

  def update
    @lecture = Lecture.find(params[:id])

    if @lecture.update(lecture_params)
      redirect_to lecture_path(@lecture), notice: "Lecture mise a jour"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @lecture = Lecture.find(params[:id])
    @lecture.destroy
    redirect_to lectures_path, notice: "Lecture supprimée avec succès"
  end

  def download_resume
    @lecture = Lecture.find(params[:id])

    unless @lecture.resume.present?
      redirect_to lecture_path(@lecture), alert: "Aucune fiche de cours disponible pour ce cours."
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

  def check_lecture_limit
    enforce_lecture_limit!
  end

  def lecture_params
    params.require(:lecture).permit(:title, :resume, :category_id, :document)
  end
end
