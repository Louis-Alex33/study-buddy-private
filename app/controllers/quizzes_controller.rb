class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_quiz_limit, only: [:create]
  before_action -> { enforce_rate_limit!(:ai_quiz, max_per_minute: 3) }, only: [:create]

  def index
    @categories = Category.includes(:quizzes).where.not(quizzes: { id: nil })
    @public_quizzes = Quiz.where(status: "public").includes(:category, :questions, :attempts).group_by(&:category)
    @shared_quizzes = Quiz.where(status: "shared").includes(:category, :questions, :attempts, challenges: [:user, :invited_users]).group_by(&:category)
  end

  def show
    @quiz = Quiz.includes(questions: :options).find(params[:id])
    @questions = @quiz.questions.ordered
    @user_attempts = @quiz.attempts.where(user: current_user).order(created_at: :desc)
    @best_attempt = @user_attempts.completed.order(score: :desc).first
  end

  def new
    @quiz = Quiz.new
  end

  def edit
    @quiz = Quiz.find(params[:id])
    @questions = @quiz.questions.includes(:options).ordered
  end

  def update
    @quiz = Quiz.find(params[:id])
    if @quiz.update(quiz_params)
      redirect_to quiz_path(@quiz), notice: "Quiz mis à jour avec succès."
    else
      @questions = @quiz.questions.includes(:options).ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def bookmark
    @quiz = Quiz.find(params[:id])
    current_user.quiz_bookmarks.find_or_create_by(quiz: @quiz)
    redirect_back fallback_location: quiz_path(@quiz), notice: "Quiz ajouté aux favoris."
  end

  def unbookmark
    @quiz = Quiz.find(params[:id])
    current_user.quiz_bookmarks.find_by(quiz: @quiz)&.destroy
    redirect_back fallback_location: quiz_path(@quiz), notice: "Quiz retiré des favoris."
  end

  def destroy
    @quiz = Quiz.find(params[:id])
    lecture = @quiz.lecture
    @quiz.destroy
    if lecture
      redirect_to lecture_path(lecture, anchor: "quiz-section"), notice: "Quiz supprimé avec succès."
    else
      redirect_back fallback_location: quizzes_path, notice: "Quiz supprimé avec succès."
    end
  end

  def create
    @quiz = Quiz.new(quiz_params)

    # Handle new category creation
    if params[:new_category_title].present?
      category = current_user.categories.find_or_create_by(title: params[:new_category_title].strip)
      @quiz.category = category
    end

    if @quiz.save
      # Générer les questions avec l'IA
      QuizGeneratorService.new(@quiz).call
      current_user.increment!(:quiz_generations_count)

      # Créer le challenge avec l'utilisateur courant comme propriétaire
      challenge = current_user.challenges.create!(quiz: @quiz)

      # Ajouter les amis invités au challenge (seulement si quiz shared)
      if @quiz.status == "shared" && params[:invited_user_ids].present?
        params[:invited_user_ids].each do |user_id|
          challenge.challenger_users.create!(user_id: user_id)
        end
      end

      redirect_to (params[:redirect_to] || challenges_path), notice: "Quiz créé avec succès !"
    else
      redirect_to (params[:redirect_to] || challenges_path), alert: "Erreur lors de la création du quiz : #{@quiz.errors.full_messages.join(', ')}"
    end
  end

  private

  def check_quiz_limit
    enforce_quiz_generation_limit!
  end

  def quiz_params
    params.require(:quiz).permit(:title, :category_id, :lecture_id, :level, :status)
  end
end
