class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.integer :provider_id, null: false
      t.string :name, null: false
      t.text :url, null: false
      t.timestamps
    end
  end
end
