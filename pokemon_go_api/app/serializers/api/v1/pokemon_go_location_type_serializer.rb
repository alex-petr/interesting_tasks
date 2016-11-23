class Api::V1::PokemonGoLocationTypeSerializer < ActiveModel::Serializer
  attributes :id, :name, :key
end
