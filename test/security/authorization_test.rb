# frozen_string_literal: true

# =============================================================================
# TESTS DE SÉCURITÉ - AUTORISATION ET CONTRÔLE D'ACCÈS
# =============================================================================
#
# Ces tests vérifient que les utilisateurs ne peuvent pas accéder aux
# ressources qui ne leur appartiennent pas (escalade horizontale de privilèges).
#
# RISQUES COUVERTS:
# - OWASP A01:2021 - Broken Access Control
# - Accès non autorisé aux lectures d'autres utilisateurs
# - Accès non autorisé aux quizzes d'autres utilisateurs
# - Accès non autorisé aux notes d'autres utilisateurs
# - Accès non autorisé aux flashcards d'autres utilisateurs
#
# EXÉCUTION:
#   rails test test/security/authorization_test.rb
#
# =============================================================================

require "test_helper"

class AuthorizationSecurityTest < ActionDispatch::IntegrationTest
  # ===========================================================================
  # SETUP - Création des utilisateurs et ressources de test
  # ===========================================================================

  setup do
    # Créer deux utilisateurs distincts avec onboarding complété
    @user_alice = User.create!(
      email: "alice_auth@test.com",
      password: "password123456",
      first_name: "Alice",
      last_name: "Test",
      onboarding_completed: true
    )

    @user_bob = User.create!(
      email: "bob_auth@test.com",
      password: "password123456",
      first_name: "Bob",
      last_name: "Test",
      onboarding_completed: true
    )

    # Créer une catégorie pour Alice
    @alice_category = @user_alice.categories.create!(title: "Catégorie Alice Auth")

    # Créer une catégorie pour Bob
    @bob_category = @user_bob.categories.create!(title: "Catégorie Bob Auth")

    # Créer une lecture pour Alice avec document attaché
    @alice_lecture = Lecture.new(
      title: "Cours privé d'Alice",
      category: @alice_category,
      user: @user_alice,
      resume: "Contenu sensible d'Alice"
    )
    @alice_lecture.document.attach(
      io: StringIO.new("Fake PDF content for Alice"),
      filename: "alice_test.pdf",
      content_type: "application/pdf"
    )
    @alice_lecture.save!

    # Créer une lecture pour Bob avec document attaché
    @bob_lecture = Lecture.new(
      title: "Cours privé de Bob",
      category: @bob_category,
      user: @user_bob,
      resume: "Contenu sensible de Bob"
    )
    @bob_lecture.document.attach(
      io: StringIO.new("Fake PDF content for Bob"),
      filename: "bob_test.pdf",
      content_type: "application/pdf"
    )
    @bob_lecture.save!

    # Créer une note pour Alice
    @alice_note = Note.create!(
      content: "Note privée d'Alice",
      lecture: @alice_lecture,
      user: @user_alice
    )

    # Créer un quiz pour Alice
    @alice_quiz = Quiz.create!(
      title: "Quiz d'Alice",
      category: @alice_category,
      lecture: @alice_lecture,
      level: 1,
      status: "public"
    )

    # Créer une flashcard pour Alice
    @alice_flashcard = Flashcard.create!(
      content: '[{"question": "Q1", "answer": "R1"}]',
      expected_answer: "Test",
      lecture: @alice_lecture
    )
  end

  teardown do
    # Nettoyage après chaque test - dans le bon ordre pour éviter les erreurs de FK
    users = User.where(email: ["alice_auth@test.com", "bob_auth@test.com"])
    user_ids = users.pluck(:id)

    # Supprimer les IP logs
    UserIpLog.where(user_id: user_ids).delete_all if defined?(UserIpLog)

    # Supprimer les ressources liées aux lectures
    lectures = Lecture.where(user_id: user_ids)
    lecture_ids = lectures.pluck(:id)

    FlashcardCompletion.where(flashcard_id: Flashcard.where(lecture_id: lecture_ids).pluck(:id)).delete_all if defined?(FlashcardCompletion)
    Flashcard.where(lecture_id: lecture_ids).delete_all
    Quiz.where(lecture_id: lecture_ids).delete_all
    Note.where(lecture_id: lecture_ids).delete_all
    Message.where(lecture_id: lecture_ids).delete_all if defined?(Message)

    # Supprimer les lectures et catégories
    Lecture.where(id: lecture_ids).delete_all
    Category.where(user_id: user_ids).delete_all

    # Supprimer les utilisateurs
    users.delete_all
  end

  # ===========================================================================
  # HELPER - Connexion utilisateur
  # ===========================================================================

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123456" }
    }
    follow_redirect! if response.redirect?
  end

  # ===========================================================================
  # TESTS: LECTURES - Escalade horizontale de privilèges
  # ===========================================================================

  test "SÉCURITÉ: un utilisateur ne peut pas voir la lecture d'un autre utilisateur" do
    sign_in_as(@user_bob)

    # Bob tente d'accéder à la lecture d'Alice
    get lecture_path(@alice_lecture)

    # ATTENDU: Redirection ou erreur 403/404
    # ACTUEL: Le test échouera si Bob peut voir la lecture d'Alice
    if response.status == 200
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob peut voir la lecture d'Alice (ID: #{@alice_lecture.id})"
    end

    assert_not_equal 200, response.status,
      "VULNÉRABILITÉ DÉTECTÉE: Bob peut voir la lecture d'Alice (ID: #{@alice_lecture.id})"
  end

  test "SÉCURITÉ: un utilisateur ne peut pas modifier la lecture d'un autre utilisateur" do
    sign_in_as(@user_bob)

    # Bob tente de modifier la lecture d'Alice
    get edit_lecture_path(@alice_lecture)

    if response.status == 200
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob peut accéder au formulaire d'édition de la lecture d'Alice"
    end

    # ATTENDU: Redirection ou erreur 403/404
    assert_not_equal 200, response.status,
      "VULNÉRABILITÉ DÉTECTÉE: Bob peut accéder au formulaire d'édition de la lecture d'Alice"
  end

  test "SÉCURITÉ: un utilisateur ne peut pas mettre à jour la lecture d'un autre utilisateur" do
    sign_in_as(@user_bob)

    original_title = @alice_lecture.title

    # Bob tente de mettre à jour la lecture d'Alice
    patch lecture_path(@alice_lecture), params: {
      lecture: { title: "Lecture piratée par Bob" }
    }

    @alice_lecture.reload

    if @alice_lecture.title != original_title
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob a pu modifier la lecture d'Alice"
    end

    # ATTENDU: La lecture ne doit pas être modifiée
    assert_equal original_title, @alice_lecture.title,
      "VULNÉRABILITÉ DÉTECTÉE: Bob a pu modifier la lecture d'Alice"
  end

  test "SÉCURITÉ: un utilisateur ne peut pas supprimer la lecture d'un autre utilisateur" do
    sign_in_as(@user_bob)

    lecture_id = @alice_lecture.id

    # Bob tente de supprimer la lecture d'Alice
    delete lecture_path(@alice_lecture)

    if !Lecture.exists?(lecture_id)
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob a pu supprimer la lecture d'Alice"
    end

    # ATTENDU: La lecture doit toujours exister
    assert Lecture.exists?(lecture_id),
      "VULNÉRABILITÉ DÉTECTÉE: Bob a pu supprimer la lecture d'Alice"
  end

  # ===========================================================================
  # TESTS: QUIZZES - Escalade horizontale de privilèges
  # ===========================================================================

  test "SÉCURITÉ: un utilisateur ne peut pas modifier le quiz d'un autre utilisateur" do
    sign_in_as(@user_bob)

    # Bob tente de modifier le quiz d'Alice
    get edit_quiz_path(@alice_quiz)

    if response.status == 200
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob peut accéder au formulaire d'édition du quiz d'Alice"
    end

    # ATTENDU: Redirection ou erreur 403/404
    assert_not_equal 200, response.status,
      "VULNÉRABILITÉ DÉTECTÉE: Bob peut accéder au formulaire d'édition du quiz d'Alice"
  end

  test "SÉCURITÉ: un utilisateur ne peut pas mettre à jour le quiz d'un autre utilisateur" do
    sign_in_as(@user_bob)

    original_title = @alice_quiz.title

    # Bob tente de mettre à jour le quiz d'Alice
    patch quiz_path(@alice_quiz), params: {
      quiz: { title: "Quiz piraté par Bob" }
    }

    @alice_quiz.reload

    if @alice_quiz.title != original_title
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob a pu modifier le quiz d'Alice"
    end

    # ATTENDU: Le quiz ne doit pas être modifié
    assert_equal original_title, @alice_quiz.title,
      "VULNÉRABILITÉ DÉTECTÉE: Bob a pu modifier le quiz d'Alice"
  end

  test "SÉCURITÉ: un utilisateur ne peut pas supprimer le quiz d'un autre utilisateur" do
    sign_in_as(@user_bob)

    quiz_id = @alice_quiz.id

    # Bob tente de supprimer le quiz d'Alice
    delete quiz_path(@alice_quiz)

    if !Quiz.exists?(quiz_id)
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob a pu supprimer le quiz d'Alice"
    end

    # ATTENDU: Le quiz doit toujours exister
    assert Quiz.exists?(quiz_id),
      "VULNÉRABILITÉ DÉTECTÉE: Bob a pu supprimer le quiz d'Alice"
  end

  # ===========================================================================
  # TESTS: NOTES - Escalade horizontale de privilèges
  # ===========================================================================

  test "SÉCURITÉ: un utilisateur ne peut pas supprimer la note d'un autre utilisateur" do
    sign_in_as(@user_bob)

    note_id = @alice_note.id

    # Bob tente de supprimer la note d'Alice
    delete note_path(@alice_note)

    if !Note.exists?(note_id)
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob a pu supprimer la note d'Alice"
    end

    # ATTENDU: La note doit toujours exister
    assert Note.exists?(note_id),
      "VULNÉRABILITÉ DÉTECTÉE: Bob a pu supprimer la note d'Alice"
  end

  # ===========================================================================
  # TESTS: FLASHCARDS - Escalade horizontale de privilèges
  # ===========================================================================

  test "SÉCURITÉ: un utilisateur ne peut pas supprimer la flashcard d'un autre utilisateur" do
    sign_in_as(@user_bob)

    flashcard_id = @alice_flashcard.id

    # Bob tente de supprimer la flashcard d'Alice
    delete flashcard_path(@alice_flashcard)

    if !Flashcard.exists?(flashcard_id)
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob a pu supprimer la flashcard d'Alice"
    end

    # ATTENDU: La flashcard doit toujours exister
    assert Flashcard.exists?(flashcard_id),
      "VULNÉRABILITÉ DÉTECTÉE: Bob a pu supprimer la flashcard d'Alice"
  end

  # ===========================================================================
  # TESTS: CATÉGORIES - Escalade horizontale de privilèges
  # ===========================================================================

  test "SÉCURITÉ: un utilisateur ne peut pas supprimer la catégorie d'un autre utilisateur" do
    sign_in_as(@user_bob)

    category_id = @alice_category.id

    # Bob tente de supprimer la catégorie d'Alice
    delete category_path(@alice_category)

    if !Category.exists?(category_id)
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Bob a pu supprimer la catégorie d'Alice"
    end

    # ATTENDU: La catégorie doit toujours exister
    assert Category.exists?(category_id),
      "VULNÉRABILITÉ DÉTECTÉE: Bob a pu supprimer la catégorie d'Alice"
  end

  # ===========================================================================
  # TESTS: ACCÈS ADMIN - Escalade verticale de privilèges
  # ===========================================================================

  test "SÉCURITÉ: un utilisateur normal ne peut pas accéder au dashboard admin" do
    sign_in_as(@user_bob)

    # Bob (utilisateur normal) tente d'accéder au dashboard admin
    get admin_dashboard_path

    if response.status == 200
      puts "\n⚠️  VULNÉRABILITÉ CONFIRMÉE: Un utilisateur normal peut accéder au dashboard admin"
    end

    # ATTENDU: Redirection ou erreur 403
    assert_not_equal 200, response.status,
      "VULNÉRABILITÉ DÉTECTÉE: Un utilisateur normal peut accéder au dashboard admin"
  end

  # ===========================================================================
  # TESTS: UTILISATEURS NON AUTHENTIFIÉS
  # ===========================================================================

  test "SÉCURITÉ: un visiteur non authentifié ne peut pas voir une lecture" do
    # Sans connexion, tenter d'accéder à une lecture
    get lecture_path(@alice_lecture)

    # ATTENDU: Redirection vers la page de connexion
    assert_redirected_to new_user_session_path,
      "VULNÉRABILITÉ DÉTECTÉE: Un visiteur non authentifié peut voir des lectures"
  end

  test "SÉCURITÉ: un visiteur non authentifié ne peut pas créer de lecture" do
    # Sans connexion, tenter de créer une lecture
    post lectures_path, params: {
      lecture: { title: "Test", category_id: @alice_category.id }
    }

    # ATTENDU: Redirection vers la page de connexion
    assert_redirected_to new_user_session_path,
      "VULNÉRABILITÉ DÉTECTÉE: Un visiteur non authentifié peut créer des lectures"
  end

  test "SÉCURITÉ: un visiteur non authentifié ne peut pas accéder au dashboard admin" do
    # Sans connexion, tenter d'accéder au dashboard admin
    get admin_dashboard_path

    # ATTENDU: Redirection vers la page de connexion
    assert_response :redirect,
      "VULNÉRABILITÉ DÉTECTÉE: Le dashboard admin est accessible sans authentification"
  end
end
