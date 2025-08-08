class AddPostedAtAndErrorMessageToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :posted_at, :datetime
    add_column :posts, :error_message, :text
  end
end
