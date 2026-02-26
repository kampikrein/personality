class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :assessment, null: false, foreign_key: true, index: { unique: true }
      t.references :anonymous_session, null: false, foreign_key: true
      t.references :personality_type, null: false, foreign_key: true
      t.string :type_code, null: false
      t.json :score_vector, default: {}
      t.json :strengths, default: []
      t.json :caution_patterns, default: []
      t.json :suggested_actions, default: []
      t.boolean :policy_blocked, default: false
      t.text :fallback_message

      t.timestamps
    end
    add_index :profiles, :type_code
  end
end
