module PlanEnforceable
  extend ActiveSupport::Concern

  private

  def enforce_lecture_limit!
    return true if current_user.can_create_lecture?

    redirect_to lectures_path,
      alert: "Vous avez atteint la limite de #{current_user.plan_limit(:max_lectures)} cours pour le plan gratuit. Passez a Studigo Pro pour un acces illimite !"
    false
  end

  def enforce_message_limit!(lecture)
    return true if current_user.can_send_message?(lecture)

    redirect_to lecture_path(lecture),
      alert: "Vous avez atteint la limite de #{current_user.plan_limit(:max_messages_per_lecture)} messages pour ce cours. Passez a Studigo Pro pour un acces illimite !"
    false
  end

  def enforce_flashcard_generation_limit!
    return true if current_user.can_generate_flashcards?

    redirect_back fallback_location: lectures_path,
      alert: "Vous avez atteint la limite de #{current_user.plan_limit(:max_flashcard_generations)} generations de flashcards. Passez a Studigo Pro pour un acces illimite !"
    false
  end

  def enforce_quiz_generation_limit!
    return true if current_user.can_generate_quiz?

    redirect_back fallback_location: quizzes_path,
      alert: "Vous avez atteint la limite de #{current_user.plan_limit(:max_quiz_generations)} creations de quiz. Passez a Studigo Pro pour un acces illimite !"
    false
  end

  def enforce_multiplayer_access!
    return true if current_user.has_multiplayer_access?

    redirect_to pricing_path,
      alert: "Le mode multijoueur est reserve aux abonnes Studigo Pro."
    false
  end
end
