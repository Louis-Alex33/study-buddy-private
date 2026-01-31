class CreateUserIpLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :user_ip_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address, null: false

      t.timestamps
    end

    add_index :user_ip_logs, [:user_id, :ip_address]
    add_index :user_ip_logs, :created_at
  end
end
