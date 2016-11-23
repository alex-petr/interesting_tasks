# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

PokemonGoLocationType.find_or_create_by name: 'PokeGym',              key: 'pokegym'
PokemonGoLocationType.find_or_create_by name: 'PokeStop',             key: 'pokestop'
PokemonGoLocationType.find_or_create_by name: 'Pokemon LiveSpotting', key: 'pokemon'
