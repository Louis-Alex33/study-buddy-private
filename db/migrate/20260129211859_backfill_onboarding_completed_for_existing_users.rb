class BackfillOnboardingCompletedForExistingUsers < ActiveRecord::Migration[7.1]
  def up
    User.update_all(onboarding_completed: true)
  end

  def down
    # No-op: cannot determine which users were pre-existing
  end
end
