class MultiplayerController < ApplicationController
  before_action :check_multiplayer_access

  def index
  end

  def league
    @user_league = current_user.user_league || current_user.create_user_league(
      rank: 'iron',
      division: 4,
      points: 0,
      wins: 0,
      losses: 0
    )
    @leaderboard = UserLeague.joins(:user).order(rank: :desc, division: :asc, points: :desc).limit(10)
  end

  private

  def check_multiplayer_access
    enforce_multiplayer_access!
  end
end
