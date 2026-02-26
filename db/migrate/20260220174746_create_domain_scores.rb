class CreateDomainScores < ActiveRecord::Migration[8.1]
  def change
    create_table :domain_scores do |t|
      t.references :assessment, null: false, foreign_key: true
      t.string :domain
      t.float :raw_score
      t.float :normalized_score
      t.float :reliability_coefficient
      t.float :consistency_index
      t.boolean :speed_flag
      t.boolean :policy_blocked

      t.timestamps
    end
  end
end
