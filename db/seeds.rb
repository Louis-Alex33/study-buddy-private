# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Nettoyage de la base de données..."
QuizRoom.destroy_all
Answer.destroy_all
Attempt.destroy_all
Option.destroy_all
Question.destroy_all
Quiz.destroy_all
FlashcardCompletion.destroy_all
Flashcard.destroy_all
Note.destroy_all
Message.destroy_all
Lecture.destroy_all
Category.destroy_all
User.destroy_all

puts "Création de l'utilisateur..."

la = User.create!(
  first_name: "LA",
  last_name: "Richoux",
  email: "la@mail.com",
  password: "secret",
  onboarding_completed: true
)

puts "Création des badges..."
Badge.seed_badges!

puts "Seed terminé !"
puts "Créé #{User.count} utilisateur(s)"
puts "Créé #{Badge.count} badges"
