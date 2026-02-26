class CreatePersonalityTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :personality_types do |t|
      t.string :code, null: false
      t.string :character_name_ko, null: false
      t.string :character_name_en, null: false
      t.text :summary_ko
      t.text :summary_en
      t.json :strengths, default: []
      t.json :caution_patterns, default: []
      t.text :collaboration_style
      t.text :conflict_style
      t.text :learning_style
      t.text :career_hints
      t.text :recovery_style

      t.timestamps
    end
    add_index :personality_types, :code, unique: true
  end
end
