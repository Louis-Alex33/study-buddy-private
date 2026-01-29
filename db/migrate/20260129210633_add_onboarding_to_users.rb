class AddOnboardingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :onboarding_completed, :boolean, default: false, null: false
  end
end
