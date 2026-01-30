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

puts "Création des catégories..."
informatique = Category.create!(title: "Informatique", user: la)
mathematiques = Category.create!(title: "Mathématiques", user: la)

puts "Création des cours..."
lecture1 = Lecture.new(
  title: "Introduction à l'Informatique",
  resume: "Cours d'introduction aux concepts fondamentaux de l'informatique",
  user: la,
  category: informatique,
)
lecture1.save!(validate: false)

lecture2 = Lecture.new(
  title: "Introduction aux Mathématiques",
  resume: "Cours d'introduction aux concepts mathématiques de base",
  user: la,
  category: mathematiques,
)
lecture2.save!(validate: false)

puts "Création des quiz..."

# Quiz Informatique - Niveau 1
info_quiz = Quiz.create!(
  title: "Bases de la Programmation",
  level: 1,
  status: "public",
  category: informatique
)

q1 = Question.create!(quiz: info_quiz, title: "Quel langage est utilisé pour le développement web côté client ?", multiple_answers: false, position: 1)
Option.create!(question: q1, content: "Python", correct: false)
Option.create!(question: q1, content: "JavaScript", correct: true)
Option.create!(question: q1, content: "Java", correct: false)
Option.create!(question: q1, content: "C++", correct: false)

q2 = Question.create!(quiz: info_quiz, title: "Quels sont des langages de programmation ?", multiple_answers: true, position: 2)
Option.create!(question: q2, content: "Ruby", correct: true)
Option.create!(question: q2, content: "HTML", correct: false)
Option.create!(question: q2, content: "Python", correct: true)
Option.create!(question: q2, content: "CSS", correct: false)

q3 = Question.create!(quiz: info_quiz, title: "Que signifie HTML ?", multiple_answers: false, position: 3)
Option.create!(question: q3, content: "Hyper Text Markup Language", correct: true)
Option.create!(question: q3, content: "High Tech Modern Language", correct: false)
Option.create!(question: q3, content: "Home Tool Markup Language", correct: false)
Option.create!(question: q3, content: "Hyperlinks and Text Markup Language", correct: false)

# Quiz Mathématiques - Niveau 1
math_quiz = Quiz.create!(
  title: "Bases des Mathématiques",
  level: 1,
  status: "public",
  category: mathematiques
)

q4 = Question.create!(quiz: math_quiz, title: "Quel est le résultat de 2 + 2 ?", multiple_answers: false, position: 1)
Option.create!(question: q4, content: "3", correct: false)
Option.create!(question: q4, content: "4", correct: true)
Option.create!(question: q4, content: "5", correct: false)
Option.create!(question: q4, content: "22", correct: false)

q5 = Question.create!(quiz: math_quiz, title: "Quel est le résultat de 5 x 3 ?", multiple_answers: false, position: 2)
Option.create!(question: q5, content: "8", correct: false)
Option.create!(question: q5, content: "12", correct: false)
Option.create!(question: q5, content: "15", correct: true)
Option.create!(question: q5, content: "53", correct: false)

q6 = Question.create!(quiz: math_quiz, title: "Quels nombres sont pairs ?", multiple_answers: true, position: 3)
Option.create!(question: q6, content: "2", correct: true)
Option.create!(question: q6, content: "3", correct: false)
Option.create!(question: q6, content: "4", correct: true)
Option.create!(question: q6, content: "7", correct: false)

puts "Création des challenges..."
Challenge.create!(user: la, quiz: info_quiz)
Challenge.create!(user: la, quiz: math_quiz)

puts "Création des badges..."
Badge.seed_badges!

puts "Seed terminé !"
puts "Créé #{User.count} utilisateur(s)"
puts "Créé #{Category.count} catégorie(s)"
puts "Créé #{Lecture.count} cours"
puts "Créé #{Quiz.count} quiz"
puts "Créé #{Question.count} questions"
puts "Créé #{Option.count} options"
puts "Créé #{Badge.count} badges"
