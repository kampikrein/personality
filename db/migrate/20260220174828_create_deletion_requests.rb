class CreateDeletionRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :deletion_requests do |t|
      t.references :anonymous_session, null: false, foreign_key: true
      t.string :request_token, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :sla_deadline

      t.timestamps
    end
    add_index :deletion_requests, :request_token, unique: true
  end
end
