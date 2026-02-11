class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    if @query.present?
      @lectures = current_user.lectures.where("title ILIKE :q OR resume ILIKE :q", q: "%#{@query}%")
      @quizzes = accessible_quizzes.where("title ILIKE ?", "%#{@query}%")
      @users = User.where("first_name ILIKE :q OR last_name ILIKE :q", q: "%#{@query}%")
                    .where.not(id: current_user.id)
    else
      @lectures = Lecture.none
      @quizzes = Quiz.none
      @users = User.none
    end

    @total_results = @lectures.count + @quizzes.count + @users.count
  end

  private

  def accessible_quizzes
    public_ids = Quiz.where(status: "public").select(:id)
    my_shared_ids = Quiz.where(status: "shared").joins(:challenges)
                        .where(challenges: { user_id: current_user.id }).select(:id)
    invited_shared_ids = Quiz.where(status: "shared").joins(challenges: :challenger_users)
                             .where(challenger_users: { user_id: current_user.id }).select(:id)

    Quiz.where(id: public_ids).or(Quiz.where(id: my_shared_ids)).or(Quiz.where(id: invited_shared_ids))
  end
end
