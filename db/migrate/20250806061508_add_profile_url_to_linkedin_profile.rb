class AddProfileUrlToLinkedinProfile < ActiveRecord::Migration[8.0]
  def change
    add_column :linkedin_profiles, :profile_picture_url, :string
  end
end
