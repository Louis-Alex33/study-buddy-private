class CreateQuizBookmarks < ActiveRecord::Migration[7.1]
  def change
    create_table :quiz_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true

      t.timestamps
    end
    add_index :quiz_bookmarks, [:user_id, :quiz_id], unique: true
  end
end
