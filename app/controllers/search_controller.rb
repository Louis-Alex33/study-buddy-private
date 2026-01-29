class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    if @query.present?
      @lectures = current_user.lectures.where("title ILIKE :q OR resume ILIKE :q", q: "%#{@query}%")
      @quizzes = Quiz.where("title ILIKE ?", "%#{@query}%")
      @users = User.where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: "%#{@query}%")
                    .where.not(id: current_user.id)
    else
      @lectures = Lecture.none
      @quizzes = Quiz.none
      @users = User.none
    end

    @total_results = @lectures.count + @quizzes.count + @users.count
  end
end
