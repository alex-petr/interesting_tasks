class CreatePokemonGoLocationTypes < ActiveRecord::Migration
  def change
    create_table :pokemon_go_location_types do |t|
      t.string :name
      t.string :key

      t.timestamps null: false
    end
  end
end
