module PlanEnforceable
  extend ActiveSupport::Concern

  private

  def enforce_lecture_limit!
    return true if current_user.can_create_lecture?

    redirect_to pricing_path,
      alert: "Tu as atteint la limite de #{current_user.plan_limit(:max_lectures)} cours du plan gratuit. Passe à Studigo Pro pour un accès illimité."
    false
  end

  def enforce_message_limit!
    return true if current_user.can_send_message?

    redirect_to pricing_path,
      alert: "Tu as utilisé tes #{current_user.plan_limit(:max_messages_total)} messages IA du plan gratuit. Passe à Studigo Pro pour un accès illimité."
    false
  end

  def enforce_flashcard_generation_limit!
    return true if current_user.can_generate_flashcards?

    redirect_to pricing_path,
      alert: "Tu as utilisé tes #{current_user.plan_limit(:max_flashcard_generations)} générations de flashcards du plan gratuit. Passe à Studigo Pro pour un accès illimité."
    false
  end

  def enforce_quiz_generation_limit!
    return true if current_user.can_generate_quiz?

    redirect_to pricing_path,
      alert: "Tu as utilisé ta #{current_user.plan_limit(:max_quiz_generations)} création de quiz du plan gratuit. Passe à Studigo Pro pour un accès illimité."
    false
  end

  def enforce_multiplayer_access!
    return true if current_user.has_multiplayer_access?

    redirect_to pricing_path,
      alert: "Le mode multijoueur est réservé aux abonnés Studigo Pro."
    false
  end
end
