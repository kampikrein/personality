class CreateConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :consents do |t|
      t.references :anonymous_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :consent_type
      t.string :consent_version
      t.boolean :granted
      t.text :consent_text_snapshot
      t.datetime :granted_at
      t.datetime :revoked_at

      t.timestamps
    end
  end
end
