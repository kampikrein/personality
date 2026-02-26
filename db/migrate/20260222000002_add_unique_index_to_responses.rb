class AddUniqueIndexToResponses < ActiveRecord::Migration[8.1]
  def change
    add_index :responses, [:assessment_id, :question_id], unique: true
  end
end
