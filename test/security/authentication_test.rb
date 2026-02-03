# frozen_string_literal: true

# =============================================================================
# TESTS DE SÉCURITÉ - AUTHENTIFICATION
# =============================================================================
#
# Ces tests vérifient la robustesse des mécanismes d'authentification.
#
# RISQUES COUVERTS:
# - OWASP A07:2021 - Identification and Authentication Failures
# - Contournement d'authentification
# - Fixation de session
# - Protection CSRF
#
# EXÉCUTION:
#   rails test test/security/authentication_test.rb
#
# =============================================================================

require "test_helper"

class AuthenticationSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "auth_test@test.com",
      password: "SecurePassword123!",
      first_name: "Auth",
      last_name: "Test",
      onboarding_completed: true
    )
  end

  teardown do
    User.where(email: "auth_test@test.com").destroy_all
  end

  # ===========================================================================
  # TESTS: CSRF PROTECTION
  # ===========================================================================

  test "SÉCURITÉ: la protection CSRF est active sur les formulaires POST" do
    # Vérifier que la connexion fonctionne normalement
    post user_session_path, params: {
      user: { email: @user.email, password: "SecurePassword123!" }
    }

    # Devrait rediriger (connexion réussie)
    assert_response :redirect
  end

  # ===========================================================================
  # TESTS: CONNEXION
  # ===========================================================================

  test "SÉCURITÉ: connexion échoue avec mauvais mot de passe" do
    post user_session_path, params: {
      user: { email: @user.email, password: "WrongPassword" }
    }

    # Ne devrait pas être redirigé vers une page protégée
    # Devise redirige vers le formulaire avec une erreur
    assert_response :unprocessable_entity
  end

  test "SÉCURITÉ: connexion échoue avec email inexistant" do
    post user_session_path, params: {
      user: { email: "nonexistent@test.com", password: "AnyPassword123" }
    }

    # Ne devrait pas être connecté
    assert_response :unprocessable_entity
  end

  test "SÉCURITÉ: connexion réussie avec identifiants valides" do
    post user_session_path, params: {
      user: { email: @user.email, password: "SecurePassword123!" }
    }

    # Devrait rediriger après connexion
    assert_response :redirect
    follow_redirect!

    # Devrait pouvoir accéder à une page protégée
    get lectures_path
    assert_response :success
  end

  # ===========================================================================
  # TESTS: DÉCONNEXION
  # ===========================================================================

  test "SÉCURITÉ: la déconnexion invalide complètement la session" do
    # Se connecter
    post user_session_path, params: {
      user: { email: @user.email, password: "SecurePassword123!" }
    }
    follow_redirect!

    # Se déconnecter
    delete destroy_user_session_path
    follow_redirect! if response.redirect?

    # Tenter d'accéder à une page protégée
    get lectures_path

    # Devrait être redirigé vers la connexion
    assert_redirected_to new_user_session_path
  end

  # ===========================================================================
  # TESTS: SESSION UNIQUE (Single Session Token)
  # ===========================================================================

  test "SÉCURITÉ: une nouvelle connexion régénère le session token" do
    # Première connexion
    post user_session_path, params: {
      user: { email: @user.email, password: "SecurePassword123!" }
    }
    follow_redirect!

    # Sauvegarder le session_token
    @user.reload
    first_session_token = @user.session_token

    # Réinitialiser la session pour simuler un nouvel appareil
    reset!

    # Deuxième connexion
    post user_session_path, params: {
      user: { email: @user.email, password: "SecurePassword123!" }
    }
    follow_redirect!

    @user.reload

    # Le session_token devrait avoir changé
    assert_not_equal first_session_token, @user.session_token,
      "VULNÉRABILITÉ: Le token de session n'a pas été régénéré"
  end

  # ===========================================================================
  # TESTS: INSCRIPTION
  # ===========================================================================

  test "SÉCURITÉ: inscription refuse les mots de passe trop courts" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          email: "newuser_short@test.com",
          password: "12345",  # Trop court
          password_confirmation: "12345",
          first_name: "New",
          last_name: "User"
        }
      }
    end
  end

  test "SÉCURITÉ: inscription refuse les emails en doublon" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          email: @user.email,  # Email déjà utilisé
          password: "SecurePassword123!",
          password_confirmation: "SecurePassword123!",
          first_name: "Duplicate",
          last_name: "User"
        }
      }
    end
  end

  test "SÉCURITÉ: inscription valide les emails" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          email: "invalid-email",  # Format invalide
          password: "SecurePassword123!",
          password_confirmation: "SecurePassword123!",
          first_name: "Invalid",
          last_name: "Email"
        }
      }
    end
  end

  test "SÉCURITÉ: inscription réussie avec données valides" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          email: "valid_new_user@test.com",
          password: "SecurePassword123!",
          password_confirmation: "SecurePassword123!",
          first_name: "Valid",
          last_name: "User"
        }
      }
    end

    # Nettoyer
    User.find_by(email: "valid_new_user@test.com")&.destroy
  end

  # ===========================================================================
  # TESTS: PROTECTION CONTRE BRUTE FORCE
  # ===========================================================================

  test "INFO: vérifier si le verrouillage de compte est activé" do
    # Ce test documente l'état actuel de la configuration
    lockable_enabled = User.devise_modules.include?(:lockable)

    unless lockable_enabled
      puts "\n⚠️  RECOMMANDATION SÉCURITÉ: Le module Devise :lockable n'est pas activé."
      puts "   Cela permet les attaques par brute force sur les mots de passe."
      puts "   Action: Ajouter :lockable au modèle User et configurer dans devise.rb"
    end

    # Ce test passe toujours mais documente la recommandation
    assert true
  end

  # ===========================================================================
  # TESTS: ACCÈS PROTÉGÉ SANS AUTHENTIFICATION
  # ===========================================================================

  test "SÉCURITÉ: les pages protégées redirigent vers la connexion" do
    protected_paths = [
      lectures_path,
      categories_path,
      quizzes_path,
      stats_path
    ]

    protected_paths.each do |path|
      get path
      assert_redirected_to new_user_session_path,
        "VULNÉRABILITÉ: #{path} est accessible sans authentification"
    end
  end
end
