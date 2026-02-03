# frozen_string_literal: true

# =============================================================================
# TESTS DE ROBUSTESSE ET RÉGRESSION
# =============================================================================
#
# Ces tests vérifient le comportement de l'application face à des entrées
# invalides, des cas limites et des comportements utilisateur inattendus.
#
# SCÉNARIOS COUVERTS:
# - Paramètres manquants ou invalides
# - Accès direct à des routes non prévues
# - Actions répétées ou abusives
# - Comportements limites (double submit, refresh, etc.)
#
# EXÉCUTION:
#   rails test test/security/robustness_test.rb
#
# =============================================================================

require "test_helper"

class RobustnessSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "robustness_test@test.com",
      password: "SecurePassword123!",
      first_name: "Robustness",
      last_name: "Test",
      onboarding_completed: true
    )
    @category = @user.categories.create!(title: "Test Category Robustness")
  end

  teardown do
    @user.destroy
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "SecurePassword123!" }
    }
    follow_redirect! if response.redirect?
  end

  def create_lecture_for_test
    lecture = Lecture.new(
      title: "Test Lecture Robustness",
      category: @category,
      user: @user
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
  # TESTS: PARAMÈTRES MANQUANTS
  # ===========================================================================

  test "ROBUSTESSE: création de catégorie sans titre" do
    sign_in_as(@user)

    assert_no_difference "Category.count" do
      post categories_path, params: {
        category: { title: "" }
      }
    end
  end

  # ===========================================================================
  # TESTS: PARAMÈTRES INVALIDES
  # ===========================================================================

  test "ROBUSTESSE: accès à une lecture inexistante" do
    sign_in_as(@user)

    # Tenter d'accéder à un ID qui n'existe pas
    begin
      get lecture_path(999999999)
      # Devrait retourner 404 ou rediriger, pas planter
      assert [404, 302].include?(response.status),
        "L'accès à une ressource inexistante devrait retourner 404 ou rediriger"
    rescue ActiveRecord::RecordNotFound
      # C'est acceptable
      assert true
    end
  end

  test "ROBUSTESSE: accès à une catégorie inexistante" do
    sign_in_as(@user)

    begin
      get category_path(999999999)
      assert [404, 302].include?(response.status)
    rescue ActiveRecord::RecordNotFound, ActionController::RoutingError
      assert true
    end
  end

  test "ROBUSTESSE: accès à un quiz inexistant" do
    sign_in_as(@user)

    begin
      get quiz_path(999999999)
      assert [404, 302].include?(response.status)
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  # ===========================================================================
  # TESTS: ACCÈS DIRECT AUX ROUTES
  # ===========================================================================

  test "ROBUSTESSE: accès direct aux routes d'édition sans ressource" do
    sign_in_as(@user)

    # Créer une lecture, puis la supprimer
    lecture = create_lecture_for_test
    lecture_id = lecture.id
    lecture.destroy

    # Tenter d'éditer la lecture supprimée
    begin
      get edit_lecture_path(lecture_id)
      assert [404, 302].include?(response.status)
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "ROBUSTESSE: accès aux routes admin sans privilèges" do
    sign_in_as(@user)

    get admin_dashboard_path

    # Ne devrait pas avoir accès
    assert_not_equal 200, response.status
  end

  # ===========================================================================
  # TESTS: DOUBLE SOUMISSION
  # ===========================================================================

  test "ROBUSTESSE: double soumission de formulaire de création de catégorie" do
    sign_in_as(@user)

    params = {
      category: { title: "Double Submit Category Test" }
    }

    # Première soumission
    post categories_path, params: params
    first_response = response.status

    # Deuxième soumission identique
    post categories_path, params: params
    second_response = response.status

    # Les deux devraient fonctionner ou être gérées
    puts "\n📊 INFO: Double submit catégorie - Première: #{first_response}, Deuxième: #{second_response}"

    # Nettoyer
    Category.where(title: "Double Submit Category Test").destroy_all
  end

  test "ROBUSTESSE: double suppression de ressource" do
    sign_in_as(@user)

    category = @user.categories.create!(title: "To Delete Twice")
    category_id = category.id

    # Première suppression
    delete category_path(category)
    first_status = response.status

    # Deuxième suppression (ressource déjà supprimée)
    begin
      delete category_path(category_id)
      # Ne devrait pas planter
      second_status = response.status
      assert [404, 302, 422].include?(second_status)
    rescue ActiveRecord::RecordNotFound
      # Acceptable
      assert true
    end
  end

  # ===========================================================================
  # TESTS: DONNÉES VOLUMINEUSES
  # ===========================================================================

  test "ROBUSTESSE: titre de catégorie très long" do
    sign_in_as(@user)

    long_title = "A" * 1000  # 1000 caractères

    post categories_path, params: {
      category: { title: long_title }
    }

    # Devrait soit créer avec troncature, soit rejeter
    # Ne devrait pas planter
    assert [200, 201, 302, 422].include?(response.status)

    # Nettoyer
    Category.where("LENGTH(title) > 500").destroy_all
  end

  # ===========================================================================
  # TESTS: CARACTÈRES SPÉCIAUX
  # ===========================================================================

  test "ROBUSTESSE: caractères Unicode dans les titres" do
    sign_in_as(@user)

    unicode_titles = [
      "Cours de français 🇫🇷",
      "日本語のコース",
      "Курс русского языка",
      "العربية",
      "עברית",
      "∑∏∫∂∆"
    ]

    unicode_titles.each do |title|
      category = @user.categories.create(title: title)

      if category.persisted?
        get lectures_path
        assert_response :success
        category.destroy
      end
    end
  end

  test "ROBUSTESSE: caractères de contrôle dans les entrées" do
    sign_in_as(@user)

    control_chars = [
      "Test\x00Null",      # Null byte
      "Test\rCarriage",    # Carriage return
      "Test\x1bEscape",    # Escape
      "Test\x7fDelete"     # Delete
    ]

    control_chars.each do |title|
      post categories_path, params: {
        category: { title: title }
      }

      # Ne devrait pas planter
      assert [200, 201, 302, 422].include?(response.status),
        "L'application a planté avec: #{title.inspect}"
    end

    # Nettoyer
    Category.where("title LIKE 'Test%'").destroy_all
  end

  # ===========================================================================
  # TESTS: SESSION EXPIRÉE
  # ===========================================================================

  test "ROBUSTESSE: action après expiration de session simulée" do
    sign_in_as(@user)

    category = @user.categories.create!(title: "Session Test Cat")

    # Simuler expiration de session en se déconnectant
    delete destroy_user_session_path

    # Tenter une action qui nécessite authentification
    delete category_path(category)

    # Devrait rediriger vers la connexion
    assert_redirected_to new_user_session_path

    # La catégorie ne devrait pas avoir été supprimée
    assert Category.exists?(category.id)

    # Nettoyer en se reconnectant
    sign_in_as(@user)
    category.destroy
  end

  # ===========================================================================
  # TESTS: REQUÊTES MALFORMÉES
  # ===========================================================================

  test "ROBUSTESSE: paramètres de pagination invalides" do
    sign_in_as(@user)

    # Si l'application utilise la pagination
    [
      { page: -1 },
      { page: "abc" },
      { page: 999999999 },
      { per_page: -1 },
      { per_page: 999999999 }
    ].each do |params|
      get lectures_path, params: params
      # Ne devrait pas planter
      assert [200, 302].include?(response.status),
        "L'application a planté avec params: #{params}"
    end
  end

  test "ROBUSTESSE: paramètres de tri invalides" do
    sign_in_as(@user)

    # Tentatives d'injection via les paramètres de tri
    [
      { sort: "id; DROP TABLE users;" },
      { order: "DESC; DELETE FROM lectures;" },
      { sort_by: "../../../etc/passwd" }
    ].each do |params|
      get lectures_path, params: params
      # Ne devrait pas planter
      assert [200, 302].include?(response.status),
        "L'application a planté avec params: #{params}"
    end
  end
end
