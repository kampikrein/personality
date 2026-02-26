class CreateAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :assessments do |t|
      t.references :anonymous_session, null: false, foreign_key: true
      t.references :question_set, null: false, foreign_key: true
      t.string :status
      t.integer :current_question_index
      t.float :completion_rate
      t.float :non_response_rate
      t.float :extreme_response_rate
      t.string :retry_token

      t.timestamps
    end
  end
end
