class PagesController < ApplicationController
  MAX_FILE_SIZE_MB = 10

  skip_before_action :authenticate_user!, only: [ :home, :legal_notice, :privacy_policy, :terms ]

  def home
    @categories = current_user&.categories&.includes(:quizzes, lectures: :flashcards)&.order(:title)
    @lecture = Lecture.new

    # Dynamic social proof stats (cached 10min, visible to non-logged-in users on landing)
    unless current_user
      @stats_flashcards = Rails.cache.fetch("stats/flashcards_count", expires_in: 10.minutes) { (Flashcard.count / 10) * 10 }
      @stats_users = Rails.cache.fetch("stats/users_count", expires_in: 10.minutes) { (User.count / 10) * 10 }
    end
  end

  def legal_notice
  end

  def privacy_policy
  end

  def terms
  end
end
