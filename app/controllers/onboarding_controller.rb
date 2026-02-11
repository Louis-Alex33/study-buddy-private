class OnboardingController < ApplicationController
  def show
    redirect_to root_path if current_user.onboarding_completed?
  end

  def complete
    current_user.update!(onboarding_completed: true)
    redirect_to root_path, notice: t("controllers.onboarding.welcome")
  end
end
