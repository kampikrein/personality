class AddUniqueIndexToDomainScores < ActiveRecord::Migration[8.1]
  def change
    add_index :domain_scores, [:assessment_id, :domain], unique: true
  end
end
