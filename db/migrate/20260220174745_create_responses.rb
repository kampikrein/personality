class CreateResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :responses do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :value
      t.integer :response_time_ms
      t.integer :sequence_number

      t.timestamps
    end
  end
end
