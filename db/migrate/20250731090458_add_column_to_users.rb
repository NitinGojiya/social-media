class AddColumnToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :linkedin_token, :string
  end
end
