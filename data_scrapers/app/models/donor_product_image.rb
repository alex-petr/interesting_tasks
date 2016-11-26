# == Schema Information
#
# Table name: donor_product_images
#
#  id               :integer          not null, primary key
#  donor_product_id :integer
#  url              :string
#  dhash            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_donor_product_images_on_donor_product_id  (donor_product_id)
#

class DonorProductImage < ActiveRecord::Base
  belongs_to :donor_product

  validates :url, uniqueness: {scope: :donor_product_id}

  after_commit :copy_to_product

  def copy_to_product
    CopyImageWorker.perform_in(1.minute, self.id)
  end

end
