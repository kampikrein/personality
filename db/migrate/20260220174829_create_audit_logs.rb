class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.string :actor_type
      t.bigint :actor_id
      t.string :action, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.json :metadata, default: {}

      t.timestamps
    end
    add_index :audit_logs, [:resource_type, :resource_id]
    add_index :audit_logs, [:actor_type, :actor_id]
  end
end
