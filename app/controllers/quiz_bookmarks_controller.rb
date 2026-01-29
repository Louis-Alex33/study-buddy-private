class QuizBookmarksController < ApplicationController
  def create
    @quiz = Quiz.find(params[:quiz_id])
    bookmark = current_user.quiz_bookmarks.build(quiz: @quiz)

    if bookmark.save
      redirect_back fallback_location: quizzes_path, notice: "Quiz ajouté aux favoris."
    else
      redirect_back fallback_location: quizzes_path, alert: "Ce quiz est déjà dans vos favoris."
    end
  end

  def destroy
    bookmark = current_user.quiz_bookmarks.find_by(quiz_id: params[:quiz_id])
    bookmark&.destroy
    redirect_back fallback_location: quizzes_path, notice: "Quiz retiré des favoris."
  end
end
