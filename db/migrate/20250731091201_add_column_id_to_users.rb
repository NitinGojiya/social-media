class AddColumnIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :linkedin_id, :string
  end
end
