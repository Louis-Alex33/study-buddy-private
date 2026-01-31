# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_01_31_090324) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "answers", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.bigint "question_id", null: false
    t.bigint "option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attempt_id", "question_id"], name: "index_answers_on_attempt_id_and_question_id"
    t.index ["attempt_id"], name: "index_answers_on_attempt_id"
    t.index ["option_id"], name: "index_answers_on_option_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "quiz_id", null: false
    t.integer "score"
    t.boolean "done", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_attempts_on_quiz_id"
    t.index ["user_id", "quiz_id"], name: "index_attempts_on_user_id_and_quiz_id"
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "icon"
    t.string "category"
    t.integer "points_required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "challenger_users", force: :cascade do |t|
    t.bigint "challenge_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_challenger_users_on_challenge_id"
    t.index ["user_id"], name: "index_challenger_users_on_user_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "quiz_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_challenges_on_quiz_id"
    t.index ["user_id"], name: "index_challenges_on_user_id"
  end

  create_table "flashcard_completions", force: :cascade do |t|
    t.string "status"
    t.bigint "user_id", null: false
    t.bigint "flashcard_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flashcard_id"], name: "index_flashcard_completions_on_flashcard_id"
    t.index ["user_id"], name: "index_flashcard_completions_on_user_id"
  end

  create_table "flashcards", force: :cascade do |t|
    t.text "content"
    t.text "expected_answer"
    t.bigint "lecture_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_flashcards_on_lecture_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "friend_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["friend_id"], name: "index_friendships_on_friend_id"
    t.index ["status"], name: "index_friendships_on_status"
    t.index ["user_id", "friend_id"], name: "index_friendships_on_user_id_and_friend_id", unique: true
    t.index ["user_id"], name: "index_friendships_on_user_id"
  end

  create_table "lectures", force: :cascade do |t|
    t.string "title"
    t.text "resume"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_lectures_on_category_id"
    t.index ["user_id"], name: "index_lectures_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "role"
    t.text "content"
    t.bigint "lecture_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["lecture_id"], name: "index_messages_on_lecture_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content"
    t.bigint "lecture_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lecture_id"], name: "index_notes_on_lecture_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "options", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.string "content", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_options_on_question_id"
  end

  create_table "pay_charges", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "subscription_id"
    t.string "processor_id", null: false
    t.integer "amount", null: false
    t.string "currency"
    t.integer "application_fee_amount"
    t.integer "amount_refunded"
    t.jsonb "metadata"
    t.jsonb "data"
    t.string "stripe_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.jsonb "data"
    t.string "stripe_account"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "processor_id", null: false
    t.boolean "default"
    t.string "type"
    t.jsonb "data"
    t.string "stripe_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "name", null: false
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.datetime "current_period_start", precision: nil
    t.datetime "current_period_end", precision: nil
    t.datetime "trial_ends_at", precision: nil
    t.datetime "ends_at", precision: nil
    t.boolean "metered"
    t.string "pause_behavior"
    t.datetime "pause_starts_at", precision: nil
    t.datetime "pause_resumes_at", precision: nil
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.jsonb "metadata"
    t.jsonb "data"
    t.string "stripe_account"
    t.string "payment_method_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.string "processor"
    t.string "event_type"
    t.jsonb "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.text "title", null: false
    t.boolean "multiple_answers", default: false, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id", "position"], name: "index_questions_on_quiz_id_and_position"
    t.index ["quiz_id"], name: "index_questions_on_quiz_id"
  end

  create_table "quiz_bookmarks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "quiz_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_quiz_bookmarks_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_bookmarks_on_user_id"
  end

  create_table "quiz_participants", force: :cascade do |t|
    t.bigint "quiz_room_id", null: false
    t.bigint "user_id", null: false
    t.integer "score"
    t.integer "correct_answers"
    t.integer "total_questions"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_room_id"], name: "index_quiz_participants_on_quiz_room_id"
    t.index ["user_id"], name: "index_quiz_participants_on_user_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.text "content"
    t.string "correct_answer"
    t.text "wrong_answers"
    t.string "category"
    t.string "difficulty"
    t.bigint "quiz_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_room_id"], name: "index_quiz_questions_on_quiz_room_id"
  end

  create_table "quiz_rooms", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.integer "max_players"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.string "difficulty"
    t.bigint "owner_id", null: false
    t.index ["owner_id"], name: "index_quiz_rooms_on_owner_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "title", null: false
    t.integer "level", default: 1, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "shared", null: false
    t.index ["category_id"], name: "index_quizzes_on_category_id"
    t.index ["level"], name: "index_quizzes_on_level"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.text "channel"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "user_badges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_user_badges_on_badge_id"
    t.index ["user_id"], name: "index_user_badges_on_user_id"
  end

  create_table "user_ip_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_user_ip_logs_on_created_at"
    t.index ["user_id", "ip_address"], name: "index_user_ip_logs_on_user_id_and_ip_address"
    t.index ["user_id"], name: "index_user_ip_logs_on_user_id"
  end

  create_table "user_leagues", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "rank", default: "iron", null: false
    t.integer "division", default: 4, null: false
    t.integer "points", default: 0, null: false
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rank", "division", "points"], name: "index_user_leagues_on_rank_and_division_and_points"
    t.index ["rank"], name: "index_user_leagues_on_rank"
    t.index ["user_id"], name: "index_user_leagues_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "points", default: 0, null: false
    t.string "plan", default: "free", null: false
    t.integer "flashcard_generations_count", default: 0, null: false
    t.integer "quiz_generations_count", default: 0, null: false
    t.boolean "onboarding_completed"
    t.string "session_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["plan"], name: "index_users_on_plan"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["session_token"], name: "index_users_on_session_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "answers", "attempts"
  add_foreign_key "answers", "options"
  add_foreign_key "answers", "questions"
  add_foreign_key "attempts", "quizzes"
  add_foreign_key "attempts", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "challenger_users", "challenges"
  add_foreign_key "challenger_users", "users"
  add_foreign_key "challenges", "quizzes"
  add_foreign_key "challenges", "users"
  add_foreign_key "flashcard_completions", "flashcards"
  add_foreign_key "flashcard_completions", "users"
  add_foreign_key "flashcards", "lectures"
  add_foreign_key "friendships", "users"
  add_foreign_key "friendships", "users", column: "friend_id"
  add_foreign_key "lectures", "categories"
  add_foreign_key "lectures", "users"
  add_foreign_key "messages", "lectures"
  add_foreign_key "messages", "users"
  add_foreign_key "notes", "lectures"
  add_foreign_key "notes", "users"
  add_foreign_key "options", "questions"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "questions", "quizzes"
  add_foreign_key "quiz_bookmarks", "quizzes"
  add_foreign_key "quiz_bookmarks", "users"
  add_foreign_key "quiz_participants", "quiz_rooms"
  add_foreign_key "quiz_participants", "users"
  add_foreign_key "quiz_questions", "quiz_rooms"
  add_foreign_key "quiz_rooms", "users", column: "owner_id"
  add_foreign_key "quizzes", "categories"
  add_foreign_key "user_badges", "badges"
  add_foreign_key "user_badges", "users"
  add_foreign_key "user_ip_logs", "users"
  add_foreign_key "user_leagues", "users"
end
