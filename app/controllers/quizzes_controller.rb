class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_quiz_limit, only: [:create]
  before_action -> { enforce_rate_limit!(:ai_quiz, max_per_minute: 3) }, only: [:create]
  before_action :set_quiz, only: [:show, :edit, :update, :destroy, :bookmark, :unbookmark]
  before_action :authorize_quiz_access!, only: [:show, :bookmark, :unbookmark]
  before_action :authorize_quiz_modification!, only: [:edit, :update, :destroy]

  def index
    @categories = Category.includes(:quizzes).where.not(quizzes: { id: nil })
    @public_quizzes = Quiz.where(status: "public").includes(:category, :questions, :attempts).group_by(&:category)

    my_shared = Quiz.where(status: "shared").joins(:challenges)
                    .where(challenges: { user_id: current_user.id })
    invited_shared = Quiz.where(status: "shared").joins(challenges: :challenger_users)
                         .where(challenger_users: { user_id: current_user.id })
    @shared_quizzes = Quiz.where(id: my_shared.select(:id))
                          .or(Quiz.where(id: invited_shared.select(:id)))
                          .includes(:category, :questions, :attempts, challenges: [:user, :invited_users])
                          .group_by(&:category)
  end

  def show
    @questions = @quiz.questions.ordered
    @user_attempts = @quiz.attempts.where(user: current_user).order(created_at: :desc)
    @best_attempt = @user_attempts.completed.order(score: :desc).first
  end

  def new
    @quiz = Quiz.new
  end

  def edit
    @questions = @quiz.questions.includes(:options).ordered
  end

  def update
    if @quiz.update(quiz_params)
      redirect_to quiz_path(@quiz), notice: t("controllers.quizzes.updated")
    else
      @questions = @quiz.questions.includes(:options).ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def bookmark
    current_user.quiz_bookmarks.find_or_create_by(quiz: @quiz)
    redirect_back fallback_location: quiz_path(@quiz), notice: t("controllers.quizzes.bookmarked")
  end

  def unbookmark
    current_user.quiz_bookmarks.find_by(quiz: @quiz)&.destroy
    redirect_back fallback_location: quiz_path(@quiz), notice: t("controllers.quizzes.unbookmarked")
  end

  def destroy
    lecture = @quiz.lecture
    @quiz.destroy
    if lecture
      redirect_to lecture_path(lecture, anchor: "quiz-section"), notice: t("controllers.quizzes.destroyed")
    else
      redirect_back fallback_location: quizzes_path, notice: t("controllers.quizzes.destroyed")
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

      redirect_to (params[:redirect_to] || challenges_path), notice: t("controllers.quizzes.created")
    else
      redirect_to (params[:redirect_to] || challenges_path), alert: t("controllers.quizzes.creation_error", errors: @quiz.errors.full_messages.join(', '))
    end
  end

  private

  def set_quiz
    @quiz = Quiz.includes(questions: :options).find(params[:id])
  end

  def authorize_quiz_access!
    return if @quiz.status == "public"
    return if @quiz.challenges.exists?(user_id: current_user.id)
    return if ChallengerUser.joins(:challenge)
                .exists?(challenges: { quiz_id: @quiz.id }, user_id: current_user.id)
    # Quiz lié à une lecture du user (généré depuis ses cours)
    return if @quiz.lecture.present? && @quiz.lecture.user == current_user

    redirect_to quizzes_path, alert: t("controllers.shared.unauthorized")
  end

  def authorize_quiz_modification!
    # Le quiz appartient à l'utilisateur si:
    # 1. Le quiz est lié à une lecture qui appartient à l'utilisateur
    # 2. OU l'utilisateur a créé un challenge pour ce quiz
    is_owner = false

    if @quiz.lecture.present?
      is_owner = @quiz.lecture.user == current_user
    else
      is_owner = current_user.challenges.exists?(quiz: @quiz)
    end

    unless is_owner
      redirect_to quizzes_path, alert: t("controllers.shared.unauthorized")
    end
  end

  def check_quiz_limit
    enforce_quiz_generation_limit!
  end

  def quiz_params
    params.require(:quiz).permit(:title, :category_id, :lecture_id, :level, :status)
  end
end
