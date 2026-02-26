class AddMissingColumnsToAnonymousSessionsAndAssessments < ActiveRecord::Migration[8.1]
  def change
    add_column :anonymous_sessions, :ip_fingerprint, :string
    add_column :anonymous_sessions, :started_at, :datetime

    add_column :assessments, :started_at, :datetime
    add_column :assessments, :completed_at, :datetime
  end
end
