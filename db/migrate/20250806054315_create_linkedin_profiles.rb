class CreateLinkedinProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :linkedin_profiles do |t|
      t.string :profile_name
      t.string :headline
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
