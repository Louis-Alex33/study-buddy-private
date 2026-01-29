class PagesController < ApplicationController
  MAX_FILE_SIZE_MB = 10

  skip_before_action :authenticate_user!, only: [ :home, :legal_notice, :privacy_policy, :terms ]

  def home
    @categories = Category.all
    @lecture = Lecture.new
  end

  def legal_notice
  end

  def privacy_policy
  end

  def terms
  end

  def message_params
    pararms.require(:message).permit(:content,:title)
  end

end
