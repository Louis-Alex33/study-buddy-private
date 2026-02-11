class AddMissingIndexes < ActiveRecord::Migration[7.1]
  def change
    # Messages ordered by lecture + time (chat display)
    add_index :messages, [:lecture_id, :created_at], name: "index_messages_on_lecture_id_and_created_at"

    # Attempts ordered by user + time (user history, stats)
    add_index :attempts, [:user_id, :created_at], name: "index_attempts_on_user_id_and_created_at"

    # Flashcard completions by user + flashcard (unique lookups)
    add_index :flashcard_completions, [:user_id, :flashcard_id], name: "index_flashcard_completions_on_user_and_flashcard", unique: true

    # Quizzes filtered by status (public/shared/private)
    add_index :quizzes, :status, name: "index_quizzes_on_status"
  end
end
