module PlanEnforceable
  extend ActiveSupport::Concern

  private

  def enforce_lecture_limit!
    return true if current_user.can_create_lecture?

    redirect_to pricing_path,
      alert: t("controllers.plan.lecture_limit", count: current_user.plan_limit(:max_lectures))
    false
  end

  def enforce_message_limit!
    return true if current_user.can_send_message?

    redirect_to pricing_path,
      alert: t("controllers.plan.message_limit", count: current_user.plan_limit(:max_messages_total))
    false
  end

  def enforce_flashcard_generation_limit!
    return true if current_user.can_generate_flashcards?

    redirect_to pricing_path,
      alert: t("controllers.plan.flashcard_limit", count: current_user.plan_limit(:max_flashcard_generations))
    false
  end

  def enforce_quiz_generation_limit!
    return true if current_user.can_generate_quiz?

    redirect_to pricing_path,
      alert: t("controllers.plan.quiz_limit", count: current_user.plan_limit(:max_quiz_generations))
    false
  end

  def enforce_multiplayer_access!
    return true if current_user.has_multiplayer_access?

    redirect_to pricing_path,
      alert: t("controllers.plan.multiplayer_restricted")
    false
  end
end
