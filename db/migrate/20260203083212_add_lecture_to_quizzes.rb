class AddLectureToQuizzes < ActiveRecord::Migration[7.1]
  def change
    add_reference :quizzes, :lecture, null: true, foreign_key: true
  end
end
