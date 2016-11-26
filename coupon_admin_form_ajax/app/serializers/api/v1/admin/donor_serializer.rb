class Api::V1::Admin::DonorSerializer < ActiveModel::Serializer
  attributes :id, :name

  def name
    object.domain
  end
end
