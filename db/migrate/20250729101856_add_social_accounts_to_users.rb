class AddSocialAccountsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :fb_token, :string
    add_column :users, :fb_page_id, :string
    add_column :users, :fb_page_token, :string
    add_column :users, :ig_user_id, :string
  end
end
