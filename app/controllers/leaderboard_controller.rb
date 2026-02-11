class LeaderboardController < ApplicationController
  def index
    @top_by_points = User.includes(:user_league).order(points: :desc).limit(20)
    @top_by_quizzes = User.joins(:attempts)
                          .includes(:user_league)
                          .where(attempts: { done: true })
                          .group("users.id")
                          .order("COUNT(attempts.id) DESC")
                          .limit(20)
    @top_by_leagues = UserLeague.joins(:user)
                                .order(
                                  Arel.sql("CASE rank
                                    WHEN 'challenger' THEN 10
                                    WHEN 'grandmaster' THEN 9
                                    WHEN 'master' THEN 8
                                    WHEN 'diamond' THEN 7
                                    WHEN 'emerald' THEN 6
                                    WHEN 'platinum' THEN 5
                                    WHEN 'gold' THEN 4
                                    WHEN 'silver' THEN 3
                                    WHEN 'bronze' THEN 2
                                    WHEN 'iron' THEN 1
                                    ELSE 0 END DESC"),
                                  division: :asc,
                                  points: :desc
                                )
                                .limit(20)
                                .includes(:user)

    @current_user_rank = User.where("points > ?", current_user.points).count + 1
  end
end
