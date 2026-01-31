class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :icon, presence: true
  validates :category, presence: true

  CATEGORIES = %w[courses quizzes flashcards social streak].freeze

  scope :by_category, ->(cat) { where(category: cat) }

  def self.seed_badges!
    badges = [
      # Cours (ordre de progression : 1 → 5 → 10 → 25)
      { name: "Premier pas", description: "Créer votre premier cours", icon: "fa-book", category: "courses", points_required: 1 },
      { name: "Étudiant assidu", description: "Créer 5 cours", icon: "fa-graduation-cap", category: "courses", points_required: 2 },
      { name: "Bibliothécaire", description: "Créer 10 cours", icon: "fa-book-open", category: "courses", points_required: 3 },
      { name: "Encyclopédie", description: "Créer 25 cours", icon: "fa-landmark", category: "courses", points_required: 4 },

      # Quiz (ordre de progression)
      { name: "Curieux", description: "Compléter votre premier quiz", icon: "fa-question-circle", category: "quizzes", points_required: 1 },
      { name: "Quiz master", description: "Compléter 10 quiz", icon: "fa-trophy", category: "quizzes", points_required: 2 },
      { name: "Perfectionniste", description: "Obtenir 100% à un quiz", icon: "fa-star", category: "quizzes", points_required: 3 },
      { name: "Sans faute", description: "Obtenir 100% à 5 quiz différents", icon: "fa-medal", category: "quizzes", points_required: 4 },

      # Flashcards (ordre de progression)
      { name: "Mémorisation", description: "Créer votre premier set de flashcards", icon: "fa-layer-group", category: "flashcards", points_required: 1 },
      { name: "Révision express", description: "Maîtriser 10 flashcards (100%)", icon: "fa-brain", category: "flashcards", points_required: 2 },

      # Social (ordre de progression)
      { name: "Social", description: "Ajouter votre premier ami", icon: "fa-user-friends", category: "social", points_required: 1 },
      { name: "Populaire", description: "Avoir 5 amis", icon: "fa-users", category: "social", points_required: 2 },

      # Progression (points réels)
      { name: "Débutant", description: "Atteindre 100 points", icon: "fa-seedling", category: "streak", points_required: 100 },
      { name: "Intermédiaire", description: "Atteindre 500 points", icon: "fa-fire", category: "streak", points_required: 500 },
      { name: "Expert", description: "Atteindre 1000 points", icon: "fa-gem", category: "streak", points_required: 1000 },
    ]

    badges.each do |attrs|
      badge = Badge.find_or_initialize_by(name: attrs[:name])
      badge.update!(attrs)
    end
  end
end
