class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :question_set, null: false, foreign_key: true
      t.string :domain, null: false
      t.integer :position, null: false
      t.text :body_ko, null: false
      t.text :body_en
      t.string :polarity, null: false, default: "positive"
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :questions, [:question_set_id, :domain, :position], unique: true
  end
end
