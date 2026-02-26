class CreateQuestionSets < ActiveRecord::Migration[8.1]
  def change
    create_table :question_sets do |t|
      t.string :version_code
      t.string :status

      t.timestamps
    end
    add_index :question_sets, :version_code, unique: true
  end
end
