class AddColumnToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :fb_post_id, :string
    add_column :posts, :ig_post_id, :string
  end
end
