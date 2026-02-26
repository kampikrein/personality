class CreateAnonymousSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :anonymous_sessions do |t|
      t.string :session_token, null: false
      t.string :ip_hash
      t.string :user_agent_hash
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
    add_index :anonymous_sessions, :session_token, unique: true
  end
end
