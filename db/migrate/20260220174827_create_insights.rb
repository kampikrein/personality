class CreateInsights < ActiveRecord::Migration[8.1]
  def change
    create_table :insights do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :context, null: false
      t.json :suggestions, default: []
      t.text :explanation

      t.timestamps
    end
    add_index :insights, [:profile_id, :context], unique: true
  end
end
