class ApplicationController < ActionController::Base
  include PlanEnforceable
  include RateLimitable

  before_action :authenticate_user!
  before_action :verify_session_token!
  before_action :enforce_ip_limit!
  before_action :check_onboarding

  private

  def verify_session_token!
    return unless user_signed_in?
    return if devise_controller?
    return if current_user.session_token.nil?

    stored_token = warden.session(:user)["session_token"] rescue nil
    return if stored_token.present? && stored_token == current_user.session_token

    sign_out(current_user)
    redirect_to new_user_session_path,
      alert: "Votre session a expiré car une connexion a été effectuée depuis un autre appareil."
  end

  def enforce_ip_limit!
    return unless user_signed_in?
    return if devise_controller?

    ip = request.remote_ip

    if current_user.ip_allowed?(ip)
      current_user.log_ip!(ip)
    else
      sign_out(current_user)
      redirect_to new_user_session_path,
        alert: "Activité suspecte détectée : trop d'appareils différents. Veuillez réessayer plus tard ou contacter le support."
    end
  end

  def check_onboarding
    return unless user_signed_in?
    return if current_user.onboarding_completed?
    return if devise_controller?
    return if controller_name == "onboarding"
    return if controller_name == "pages" && %w[legal_notice privacy_policy terms].include?(action_name)

    redirect_to onboarding_path
  end
end
