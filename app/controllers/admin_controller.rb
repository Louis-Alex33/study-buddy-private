class AdminController < ApplicationController
  before_action :require_admin!

  def dashboard
    @total_users = User.count
    @pro_users = User.where(plan: "pro").count
    @free_users = User.where(plan: "free").count
    @total_lectures = Lecture.count
    @total_quizzes = Quiz.count
    @total_attempts = Attempt.count
    @recent_users = User.order(created_at: :desc).limit(10)
    @users_this_week = User.where("created_at >= ?", 1.week.ago).count
    @users_this_month = User.where("created_at >= ?", 1.month.ago).count
  end

  private

  def require_admin!
    unless current_user.admin?
      redirect_to root_path, alert: t("controllers.admin.unauthorized")
    end
  end
end
