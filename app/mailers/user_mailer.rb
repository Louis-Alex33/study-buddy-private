class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: @user.email, subject: "Bienvenue sur Studigo !")
  end

  def quiz_result(attempt)
    @attempt = attempt
    @user = attempt.user
    @quiz = attempt.quiz
    mail(to: @user.email, subject: "Résultat de ton quiz : #{@quiz.title}")
  end
end
