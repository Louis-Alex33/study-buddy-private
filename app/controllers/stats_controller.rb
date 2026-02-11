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
    @perfect_scores = @user.attempts.completed.joins(quiz: :questions)
                          .group("attempts.id", "attempts.score")
                          .having("attempts.score = COUNT(questions.id)")
                          .count.size

    # Flashcards
    @total_flashcard_completions = @user.flashcard_completions.count
    @mastered_flashcards = @user.flashcard_completions.where("CAST(status AS INTEGER) >= 80").count

    # Points et badges
    @total_points = @user.points
    @badges = @user.badges.order(:category, :points_required)
    @all_badges = Badge.all.order(:category, :points_required)

    # Activité récente (dernières 4 semaines) — batch queries
    four_weeks_ago = 3.weeks.ago.beginning_of_week
    attempts_by_week = @user.attempts.where("created_at >= ?", four_weeks_ago)
                           .group_by { |a| a.created_at.beginning_of_week.to_date }
    lectures_by_week = @user.lectures.where("created_at >= ?", four_weeks_ago)
                           .group_by { |l| l.created_at.beginning_of_week.to_date }

    @weekly_activity = (0..3).map do |weeks_ago|
      start_date = weeks_ago.weeks.ago.beginning_of_week
      week_key = start_date.to_date
      {
        week: start_date.strftime("%d/%m"),
        attempts: (attempts_by_week[week_key] || []).count,
        lectures: (lectures_by_week[week_key] || []).count
      }
    end.reverse

    # League
    @league = @user.user_league
  end
end
