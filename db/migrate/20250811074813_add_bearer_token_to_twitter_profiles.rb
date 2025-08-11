class AddBearerTokenToTwitterProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :twitter_profiles, :bearer_token, :string
  end
end
