class CreatePokemonGoLocations < ActiveRecord::Migration
  def change
    create_table :pokemon_go_locations do |t|
      t.references :pokemon_go_user, index: true
      t.string :title
      t.decimal :lat, precision: 11, scale: 8
      t.decimal :lng, precision: 11, scale: 8
      t.integer :points_score, default: 1, null: false
      t.references :pokemon_go_location_type

      t.timestamps null: false
    end

    add_index :pokemon_go_locations, :lat
    add_index :pokemon_go_locations, :lng
    add_index :pokemon_go_locations, [:lat, :lng]
  end
end
