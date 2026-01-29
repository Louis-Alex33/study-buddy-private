class AddUserIdToCategories < ActiveRecord::Migration[7.1]
  def up
    add_reference :categories, :user, null: true, foreign_key: true

    # Assign existing categories to the first user, or delete orphaned ones
    if User.any?
      default_user = User.first
      Category.where(user_id: nil).find_each do |cat|
        # If a lecture uses this category, assign it to the lecture's user
        lecture = Lecture.find_by(category_id: cat.id)
        if lecture
          cat.update_columns(user_id: lecture.user_id)
        else
          # Assign to default user if no lectures use it
          cat.update_columns(user_id: default_user.id)
        end
      end
    end

    change_column_null :categories, :user_id, false
  end

  def down
    remove_reference :categories, :user
  end
end
