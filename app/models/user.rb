class User < ApplicationRecord
  include Subscribable

  pay_customer stripe_attributes: :stripe_attributes

  has_many :lectures, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :flashcard_completions, dependent: :destroy
  has_many :flashcards, through: :flashcard_completions
  has_many :attempts, dependent: :destroy
  has_many :challenges
  has_many :challenger_users
  has_many :invited_challenges, through: :challenger_users, source: :challenge
  has_one :user_league, dependent: :destroy
  has_many :quiz_participants, dependent: :destroy
  has_many :quiz_rooms, through: :quiz_participants
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges
  has_many :quiz_bookmarks, dependent: :destroy
  has_many :bookmarked_quizzes, through: :quiz_bookmarks, source: :quiz
  has_many :user_ip_logs, dependent: :destroy

  # Friendships - demandes envoyées
  has_many :sent_friendships, class_name: 'Friendship', foreign_key: 'user_id', dependent: :destroy
  # Friendships - demandes reçues
  has_many :received_friendships, class_name: 'Friendship', foreign_key: 'friend_id', dependent: :destroy

  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable

  after_create :send_welcome_email

  # Retourne tous les amis acceptés (dans les deux sens)
  def friends
    friend_ids = sent_friendships.accepted.pluck(:friend_id) +
                 received_friendships.accepted.pluck(:user_id)
    User.where(id: friend_ids)
  end

  # Demandes d'ami en attente reçues
  def pending_friend_requests
    received_friendships.pending
  end

  # Demandes d'ami en attente envoyées
  def sent_pending_requests
    sent_friendships.pending
  end

  # Vérifie si deux utilisateurs sont amis (requête SQL directe, sans charger tous les amis)
  def friend_with?(user)
    sent_friendships.accepted.exists?(friend_id: user.id) ||
      received_friendships.accepted.exists?(user_id: user.id)
  end

  # Vérifie s'il y a une demande en attente avec un utilisateur
  def pending_request_with?(user)
    sent_friendships.pending.exists?(friend_id: user.id) ||
      received_friendships.pending.exists?(user_id: user.id)
  end

  # Retourne le nom complet ou l'email
  def display_name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    else
      email.split('@').first
    end
  end

  # Ajouter des points au user
  def add_points(amount)
    increment!(:points, amount)
  end

  # Créer la ligue si elle n'existe pas
  def ensure_league!
    create_user_league! unless user_league
  end

  def has_badge?(badge_name)
    badges.exists?(name: badge_name)
  end

  def bookmarked?(quiz)
    quiz_bookmarks.exists?(quiz: quiz)
  end

  def check_and_award_badges!
    Badge.find_each do |badge|
      next if has_badge?(badge.name)
      award_badge!(badge) if badge_earned?(badge)
    end
  end

  def badge_earned?(badge)
    case badge.name
    when "Premier pas" then lectures.count >= 1
    when "Étudiant assidu" then lectures.count >= 5
    when "Bibliothécaire" then lectures.count >= 10
    when "Encyclopédie" then lectures.count >= 25
    when "Curieux" then attempts.completed.count >= 1
    when "Quiz master" then attempts.completed.count >= 10
    when "Perfectionniste"
      attempts.completed
              .joins(quiz: :questions)
              .group("attempts.id", "attempts.score")
              .having("attempts.score = COUNT(questions.id)")
              .exists?
    when "Sans faute"
      attempts.completed
              .joins(quiz: :questions)
              .group("attempts.id", "attempts.score", "attempts.quiz_id")
              .having("attempts.score = COUNT(questions.id)")
              .select("attempts.quiz_id").distinct.count >= 5
    when "Mémorisation" then flashcard_completions.count >= 1
    when "Révision express" then flashcard_completions.where("CAST(status AS INTEGER) >= 100").count >= 10
    when "Social" then friends.count >= 1
    when "Populaire" then friends.count >= 5
    when "Débutant" then points >= 100
    when "Intermédiaire" then points >= 500
    when "Expert" then points >= 1000
    else false
    end
  end

  def award_badge!(badge)
    user_badges.create!(badge: badge)
  end

  def stripe_attributes(pay_customer)
    {
      metadata: {
        pay_customer_id: pay_customer.id,
        user_id: id
      }
    }
  end

  private

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
