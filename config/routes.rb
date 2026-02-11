Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Legal pages
  get "mentions-legales", to: "pages#legal_notice", as: :legal_notice
  get "politique-de-confidentialite", to: "pages#privacy_policy", as: :privacy_policy
  get "conditions-generales", to: "pages#terms", as: :terms

  # Subscription / Pricing
  get "tarifs", to: "subscriptions#pricing", as: :pricing
  get "mon-abonnement", to: "subscriptions#manage", as: :subscription_manage
  post "checkout", to: "subscriptions#checkout", as: :subscription_checkout
  get "checkout/succes", to: "subscriptions#success", as: :subscription_success
  get "portail", to: "subscriptions#portal", as: :subscription_portal

  # Admin
  get "admin", to: "admin#dashboard", as: :admin_dashboard

  # Onboarding
  get "bienvenue", to: "onboarding#show", as: :onboarding
  patch "bienvenue/complete", to: "onboarding#complete", as: :complete_onboarding

  # Search
  get "recherche", to: "search#index", as: :search

  # Stats
  get "statistiques", to: "stats#index", as: :stats

  # Leaderboard
  get "classement", to: "leaderboard#index", as: :leaderboard

  # Multiplayer section
  get 'multiplayer', to: 'multiplayer#index', as: :multiplayer
  get 'league', to: 'multiplayer#league', as: :league

  # Real-time quizzes
  resources :real_time_quizzes, only: [:index, :new, :create, :show] do
    member do
      post :join
      delete :leave
      post :start
      post :submit_answer
      post :finish
    end
  end

  # Social / Friends system
  resources :friendships, only: [:index, :create, :destroy] do
    member do
      patch :accept
      patch :reject
    end
  end

  # Categories
  resources :categories, only: [:create, :destroy]

  # Users listing and profiles
  resources :users, only: [:index, :show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :uploads, only: [:index, :create]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Custom health check for Heroku cold start ping
  get "health", to: "health#show"

  resources :lectures, only: %i[index show edit update new create destroy] do
    member do
      get :download_resume
      post :re_analyze
    end
    resources :notes, only: %i[new create]
    resources :messages, only: %i[new create]
    resources :flashcards, only: %i[new create]
  end

  # New quiz system - standalone, organized by category
  resources :quizzes, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :attempts, only: [:create, :show] do
      member do
        patch :submit
      end
    end
    # Bookmarks
    post :bookmark, on: :member
    delete :unbookmark, on: :member
  end

  resources :notes, only: :destroy

  resources :challenges, only: [:index, :new, :destroy] do
    resources :challenge_users, only: [:create, :show]
  end


  resources :flashcards, only: [:show, :destroy] do
    member do
      patch :update_progress
    end
    resources :flashcard_completions
  end
  # Defines the root path route ("/")
  # root "posts#index"
end
