class CreatePokemonGoUsers < ActiveRecord::Migration
  def change
    create_table :pokemon_go_users do |t|
      t.string :access_token
      t.string :user_id
      t.string :name
      t.string :link
      t.string :locale
      t.string :picture
      t.decimal :lat, precision: 11, scale: 8
      t.decimal :lng, precision: 11, scale: 8
      t.integer :points_score, default: 0, null: false

      t.timestamps null: false
    end

    add_index :pokemon_go_users, :lat
    add_index :pokemon_go_users, :lng
    add_index :pokemon_go_users, [:lat, :lng]
  end
end
