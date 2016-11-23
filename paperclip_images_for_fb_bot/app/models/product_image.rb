# == Schema Information
#
# Table name: product_images
#
#  id                 :integer          not null, primary key
#  product_id         :integer
#  url                :string
#  dhash              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  image_file_name    :string
#  image_content_type :string
#  image_file_size    :integer
#  image_updated_at   :datetime
#
# Indexes
#
#  index_product_images_on_product_id  (product_id)
#

class ProductImage < ActiveRecord::Base
  # Image size (width x height) for FaceBook Bot images with aspect ratio 1.91:1.
  # Read more: https://developers.facebook.com/docs/messenger-platform/send-api-reference/generic-template#element.
  # Important note: image size goes without options, because there will be addition some padding
  # borders to the top and bottom of the image (and to the sides to be sure) to make the final
  # image always same size using `-extent` convert option below.
  FB_BOT_IMAGE_SIZE = '500x260'

  belongs_to :product

  has_attached_file :image,
                    styles: {
                      large:  '700x700>',
                      medium: '340x340#',
                      small:  '239x239#',
                      thumb:  '50x50#',
                      fb_bot: FB_BOT_IMAGE_SIZE
                    },
                    convert_options: { fb_bot: "-background white -gravity center -extent #{FB_BOT_IMAGE_SIZE}" },
                    processors: [:thumbnail, :paperclip_optimizer],
                    default_url: '/images/:style/missing.png'
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  validates :url, uniqueness: {scope: :product_id}, unless: Proc.new{|i| i.url.blank?}
end
