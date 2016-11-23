# == Schema Information
#
# Table name: coupon_images
#
#  id                 :integer          not null, primary key
#  name               :string
#  image_file_name    :string
#  image_content_type :string
#  image_file_size    :integer
#  image_updated_at   :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class CouponImage < ActiveRecord::Base
  has_many :coupons, dependent: :nullify

  has_attached_file :image,
                    styles: { large: '600x380>', medium: '380x240>', thumb: '120x120>' },
                    processors: [:thumbnail, :paperclip_optimizer],
                    default_url: '/images/:style/missing.png'
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  validates_attachment_presence :image

  before_save :default_name

  def default_name
    self.name = self.image_file_name if self.name.blank?
  end
end
