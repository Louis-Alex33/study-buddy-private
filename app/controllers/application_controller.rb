class ApplicationController < ActionController::Base
  include PlanEnforceable
  include RateLimitable

  before_action :authenticate_user!
  before_action :check_onboarding

  private

  def check_onboarding
    return unless user_signed_in?
    return if current_user.onboarding_completed?
    return if devise_controller?
    return if controller_name == "onboarding"
    return if controller_name == "pages" && %w[legal_notice privacy_policy terms].include?(action_name)

    redirect_to onboarding_path
  end
end
