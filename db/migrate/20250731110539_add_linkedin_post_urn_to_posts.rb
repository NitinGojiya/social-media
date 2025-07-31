class AddLinkedinPostUrnToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :linkedin_post_urn, :string
  end
end
