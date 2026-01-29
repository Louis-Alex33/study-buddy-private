class StatsController < ApplicationController
  def index
    @user = current_user

    # Cours
    @total_lectures = @user.lectures.count
    @lectures_by_category = @user.lectures.joins(:category).group("categories.title").count

    # Quiz
    @total_attempts = @user.attempts.completed.count
    @average_score = @user.attempts.completed.average(:score)&.round(1) || 0
    @best_score_attempt = @user.attempts.completed.order(score: :desc).first
    @perfect_scores = @user.attempts.completed.select { |a| a.percentage_score == 100 }.count

    # Flashcards
    @total_flashcard_completions = @user.flashcard_completions.count
    @mastered_flashcards = @user.flashcard_completions.where("CAST(status AS INTEGER) >= 80").count

    # Points et badges
    @total_points = @user.points
    @badges = @user.badges.order(:category)
    @all_badges = Badge.all.order(:category)

    # Activité récente (dernières 4 semaines)
    @weekly_activity = (0..3).map do |weeks_ago|
      start_date = weeks_ago.weeks.ago.beginning_of_week
      end_date = weeks_ago.weeks.ago.end_of_week
      {
        week: start_date.strftime("%d/%m"),
        attempts: @user.attempts.where(created_at: start_date..end_date).count,
        lectures: @user.lectures.where(created_at: start_date..end_date).count
      }
    end.reverse

    # League
    @league = @user.user_league
  end
end
