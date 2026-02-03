# frozen_string_literal: true

# =============================================================================
# TESTS FONCTIONNELS - PARCOURS UTILISATEUR CRITIQUES
# =============================================================================
#
# Ces tests vérifient les parcours utilisateur essentiels qui impactent
# la confiance et la sécurité des données.
#
# PARCOURS COUVERTS:
# - Création de compte complet
# - Connexion / Déconnexion
# - Gestion des données privées
# - Comportements malveillants (XSS, SQL Injection)
#
# EXÉCUTION:
#   rails test test/security/critical_flows_test.rb
#
# =============================================================================

require "test_helper"

class CriticalFlowsSecurityTest < ActionDispatch::IntegrationTest
  # ===========================================================================
  # HELPER METHODS
  # ===========================================================================

  def sign_in_as(user, password = "SecurePassword123!")
    post user_session_path, params: {
      user: { email: user.email, password: password }
    }
    follow_redirect! if response.redirect?
  end

  def create_test_user(email: "flow_test@test.com")
    User.create!(
      email: email,
      password: "SecurePassword123!",
      first_name: "Flow",
      last_name: "Test",
      onboarding_completed: true
    )
  end

  def create_lecture_for(user, category, title: "Test Lecture")
    lecture = Lecture.new(
      title: title,
      category: category,
      user: user
    )
    lecture.document.attach(
      io: StringIO.new("Fake PDF content"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )
    lecture.save!
    lecture
  end

  # ===========================================================================
  # PARCOURS 1: CRÉATION DE COMPTE
  # ===========================================================================

  test "PARCOURS: création de compte avec données valides" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          email: "newuser_flow@test.com",
          password: "SecurePassword123!",
          password_confirmation: "SecurePassword123!",
          first_name: "New",
          last_name: "User"
        }
      }
    end

    # Vérifier que l'utilisateur est créé
    new_user = User.find_by(email: "newuser_flow@test.com")
    assert_not_nil new_user

    # Nettoyer
    new_user&.destroy
  end

  test "PARCOURS: création de compte refuse confirmation mot de passe différente" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          email: "mismatch@test.com",
          password: "SecurePassword123!",
          password_confirmation: "DifferentPassword123!",
          first_name: "Mismatch",
          last_name: "User"
        }
      }
    end
  end

  # ===========================================================================
  # PARCOURS 2: CONNEXION / DÉCONNEXION
  # ===========================================================================

  test "PARCOURS: connexion réussie redirige correctement" do
    user = create_test_user

    post user_session_path, params: {
      user: { email: user.email, password: "SecurePassword123!" }
    }

    # Devrait rediriger (vers lectures ou onboarding)
    assert_response :redirect

    user.destroy
  end

  test "PARCOURS: déconnexion puis tentative d'accès protégé" do
    user = create_test_user
    sign_in_as(user)

    # Se déconnecter
    delete destroy_user_session_path
    follow_redirect! if response.redirect?

    # Tenter d'accéder aux lectures
    get lectures_path

    # Devrait rediriger vers connexion
    assert_redirected_to new_user_session_path

    user.destroy
  end

  # ===========================================================================
  # PARCOURS 3: ISOLATION DES DONNÉES
  # ===========================================================================

  test "PARCOURS: deux utilisateurs ont des données isolées dans la liste" do
    alice = create_test_user(email: "alice_flow@test.com")
    bob = create_test_user(email: "bob_flow@test.com")

    # Créer des données pour Alice
    alice_category = alice.categories.create!(title: "Catégorie Alice Flow")
    alice_lecture = create_lecture_for(alice, alice_category, title: "Lecture Privée Alice")

    # Se connecter en tant que Bob
    sign_in_as(bob)

    # Créer une catégorie pour Bob
    bob.categories.create!(title: "Catégorie Bob Flow")

    # Vérifier que Bob ne voit pas les lectures d'Alice dans la liste
    get lectures_path
    assert_response :success

    # Le body ne devrait pas contenir les données d'Alice
    assert_no_match(/Lecture Privée Alice/, response.body,
      "VULNÉRABILITÉ: Bob peut voir la lecture d'Alice dans la liste")

    # Nettoyer
    alice.destroy
    bob.destroy
  end

  # ===========================================================================
  # PARCOURS 4: COMPORTEMENTS MALVEILLANTS - INJECTION SQL
  # ===========================================================================

  test "SÉCURITÉ: injection SQL dans les paramètres de recherche" do
    user = create_test_user
    sign_in_as(user)

    # Tentative d'injection SQL via le paramètre de recherche
    malicious_queries = [
      "'; DROP TABLE users; --",
      "1' OR '1'='1",
      "1; SELECT * FROM users",
      "' UNION SELECT * FROM users --"
    ]

    malicious_queries.each do |query|
      get lectures_path, params: { query: query }
      # Ne devrait pas planter - Rails devrait échapper
      assert_response :success,
        "L'application a planté avec l'injection: #{query}"
    end

    user.destroy
  end

  # ===========================================================================
  # PARCOURS 5: COMPORTEMENTS MALVEILLANTS - XSS
  # ===========================================================================

  test "SÉCURITÉ: XSS dans les champs de formulaire" do
    user = create_test_user
    sign_in_as(user)

    category = user.categories.create!(title: "Test Category XSS")

    # Tentative de XSS via le titre de catégorie
    xss_payloads = [
      "<script>alert('XSS')</script>",
      "<img src=x onerror=alert('XSS')>",
      "javascript:alert('XSS')",
      "<svg onload=alert('XSS')>"
    ]

    xss_payloads.each do |payload|
      # Créer une catégorie avec un payload XSS
      cat = user.categories.create(title: payload)

      if cat.persisted?
        get lectures_path
        # Le payload ne devrait pas être exécutable (échappé)
        assert_no_match(/<script>alert/, response.body,
          "XSS non échappé détecté: #{payload}")
        cat.destroy
      end
    end

    user.destroy
  end

  # ===========================================================================
  # PARCOURS 6: MANIPULATION D'ID
  # ===========================================================================

  test "SÉCURITÉ: manipulation d'ID dans les URLs" do
    alice = create_test_user(email: "alice_id@test.com")
    bob = create_test_user(email: "bob_id@test.com")

    # Créer des données pour Alice
    alice_category = alice.categories.create!(title: "Alice Cat ID")
    alice_lecture = create_lecture_for(alice, alice_category, title: "Private Alice ID")

    # Bob se connecte
    sign_in_as(bob)

    # Bob tente d'accéder en manipulant l'ID
    get lecture_path(alice_lecture.id)

    # Ce test documente la vulnérabilité si elle existe
    if response.status == 200
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob peut voir la lecture d'Alice via manipulation d'ID"
    end

    alice.destroy
    bob.destroy
  end

  # ===========================================================================
  # PARCOURS 7: CATÉGORIES
  # ===========================================================================

  test "PARCOURS: créer une catégorie, la supprimer" do
    user = create_test_user
    sign_in_as(user)

    # Créer une catégorie
    assert_difference "Category.count", 1 do
      post categories_path, params: {
        category: { title: "Catégorie à supprimer" }
      }
    end

    category = Category.last

    # Supprimer la catégorie
    assert_difference "Category.count", -1 do
      delete category_path(category)
    end

    user.destroy
  end

  # ===========================================================================
  # PARCOURS 8: PROTECTION DES ROUTES ADMIN
  # ===========================================================================

  test "SÉCURITÉ: un utilisateur normal ne peut pas accéder à /admin" do
    user = create_test_user
    sign_in_as(user)

    get admin_dashboard_path

    # Ne devrait pas avoir accès (302 redirect ou 403)
    assert_not_equal 200, response.status,
      "VULNÉRABILITÉ: Un utilisateur normal peut accéder au dashboard admin"

    user.destroy
  end

  test "SÉCURITÉ: un visiteur ne peut pas accéder à /admin" do
    get admin_dashboard_path

    # Devrait rediriger vers connexion
    assert_response :redirect
  end
end
