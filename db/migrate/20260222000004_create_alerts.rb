class CreateAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :alerts do |t|
      t.string :alert_type, null: false
      t.string :severity, null: false, default: "medium"
      t.string :status, null: false, default: "open"
      t.text :message
      t.text :notes
      t.json :metadata, default: {}
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :alerts, :status
    add_index :alerts, :severity
  end
end
