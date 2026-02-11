class QuizBookmarksController < ApplicationController
  def create
    @quiz = Quiz.find(params[:quiz_id])
    bookmark = current_user.quiz_bookmarks.build(quiz: @quiz)

    if bookmark.save
      redirect_back fallback_location: quizzes_path, notice: t("controllers.quiz_bookmarks.bookmarked")
    else
      redirect_back fallback_location: quizzes_path, alert: t("controllers.quiz_bookmarks.already_bookmarked")
    end
  end

  def destroy
    bookmark = current_user.quiz_bookmarks.find_by(quiz_id: params[:quiz_id])
    bookmark&.destroy
    redirect_back fallback_location: quizzes_path, notice: t("controllers.quiz_bookmarks.unbookmarked")
  end
end
