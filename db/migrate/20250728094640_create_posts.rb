class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :caption
      t.integer :fb, default: 0
      t.integer :ig, default: 0
      t.integer :linkedin, default: 0
      t.integer :twitter, default: 0
      t.integer :status
      t.references :user, null: false, foreign_key: true

      t.datetime :scheduled_at
      t.timestamps
    end
  end
end
