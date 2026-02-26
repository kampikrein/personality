class AddWave2Indexes < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :email, unique: true
    add_index :deletion_requests, :sla_deadline
  end
end
