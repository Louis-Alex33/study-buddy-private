class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friendship, only: [:accept, :reject, :destroy]

  def index
    @friends = current_user.friends
    @pending_requests = current_user.pending_friend_requests.includes(:user)
    @sent_requests = current_user.sent_pending_requests.includes(:friend)
  end

  def create
    friend = User.find(params[:friend_id])

    # Vérifier si une amitié existe déjà
    if current_user.friend_with?(friend)
      redirect_back fallback_location: users_path, alert: t("controllers.friendships.already_friends")
      return
    end

    # Vérifier si une demande est déjà en attente
    if current_user.pending_request_with?(friend)
      redirect_back fallback_location: users_path, alert: t("controllers.friendships.request_pending")
      return
    end

    @friendship = current_user.sent_friendships.build(friend: friend, status: 'pending')

    if @friendship.save
      redirect_back fallback_location: users_path, notice: t("controllers.friendships.request_sent", name: friend.display_name)
    else
      redirect_back fallback_location: users_path, alert: @friendship.errors.full_messages.join(', ')
    end
  end

  def accept
    if @friendship.friend == current_user
      @friendship.accepted!
      current_user.check_and_award_badges!
      @friendship.user.check_and_award_badges!
      redirect_to friendships_path, notice: t("controllers.friendships.accepted")
    else
      redirect_to friendships_path, alert: t("controllers.friendships.unauthorized_action")
    end
  end

  def reject
    if @friendship.friend == current_user
      @friendship.rejected!
      redirect_to friendships_path, notice: t("controllers.friendships.rejected")
    else
      redirect_to friendships_path, alert: t("controllers.friendships.unauthorized_action")
    end
  end

  def destroy
    if @friendship.user == current_user || @friendship.friend == current_user
      @friendship.destroy
      redirect_to friendships_path, notice: t("controllers.friendships.destroyed")
    else
      redirect_to friendships_path, alert: t("controllers.friendships.unauthorized_action")
    end
  end

  private

  def set_friendship
    @friendship = Friendship.find(params[:id])
  end
end
