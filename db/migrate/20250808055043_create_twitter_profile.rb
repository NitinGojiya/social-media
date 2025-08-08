class CreateTwitterProfile < ActiveRecord::Migration[8.0]
  def change
    create_table :twitter_profiles do |t|
      t.string :name
      t.string :nickname
      t.string :image
      t.string :token
      t.string :secret
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
