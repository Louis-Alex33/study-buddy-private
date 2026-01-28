class AddUsageCountersToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :flashcard_generations_count, :integer, default: 0, null: false
    add_column :users, :quiz_generations_count, :integer, default: 0, null: false
  end
end
