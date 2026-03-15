class FixConsentsNullConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :consents, :user_id, true
    change_column_null :consents, :anonymous_session_id, true
  end
end
