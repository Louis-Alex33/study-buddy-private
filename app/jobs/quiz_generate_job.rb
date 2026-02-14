class QuizGenerateJob < ApplicationJob
  queue_as :default

  def perform(quiz, user, redirect_to: nil, invited_user_ids: [])
    # Générer les questions avec l'IA
    QuizGeneratorService.new(quiz).call
    user.increment!(:quiz_generations_count)

    # Créer le challenge avec l'utilisateur comme propriétaire
    challenge = user.challenges.create!(quiz: quiz)

    # Ajouter les amis invités au challenge (seulement si quiz shared)
    if quiz.status == "shared" && invited_user_ids.present?
      invited_user_ids.each do |user_id|
        challenge.challenger_users.create!(user_id: user_id)
      end
    end
  rescue => e
    Rails.logger.error "QuizGenerateJob error for quiz #{quiz.id}: #{e.message}"
  end
end
