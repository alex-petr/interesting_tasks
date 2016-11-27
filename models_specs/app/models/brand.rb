# == Schema Information
#
# Table name: brands
#
#  id                :integer          not null, primary key
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  path              :string
#  logo_file_name    :string
#  logo_content_type :string
#  logo_file_size    :integer
#  logo_updated_at   :datetime
#  home_page         :boolean          default(FALSE), not null
#  seo_text_header   :text
#  seo_text_footer   :text
#  custom            :boolean          default(FALSE), not null
#
# Indexes
#
#  index_brands_on_custom  (custom)
#  index_brands_on_name    (name)
#

class Brand < ActiveRecord::Base
  attr_accessor :delete_logo

  has_many :donor_products
  has_many :products
  has_many :coupons

  has_many :category_brands
  has_many :categories, through: :category_brands, dependent: :destroy

  has_attached_file :logo,
                    styles: { large: '600x380>', medium: '380x240>', thumb: '120x120>' },
                    processors: [:thumbnail, :paperclip_optimizer],
                    default_url: '/images/:style/missing.png'
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/

  # Update ElasticSearch index.
  # update_index 'products#brand', :self

  default_scope { where(custom: false) }

  validates :name, :path, presence: true, uniqueness: true

  before_validation :normalize_name, on: :create
  before_validation :process_path, on: :create

  before_update :remove_logo

  ALLOWED = " 1234567890qwertyuiopasdfghjklzxcvbnmกขคฆจฉชฌตฏฐฑฒถทธปผพภบฎดซศษสฟฝหฮลฬรยญวอนณมงเแไโใ๑๒๓๔๕๖๗๘๙๐QWERTYUIOPLKJHGFDSAZXCVBNM"

  def process_path
    path = ''
    self.name.each_char {|c| path << c if Brand::ALLOWED.include?(c)}
    self.path = path.strip.gsub(/ /, '-').downcase
    self.path = "#{self.path}-#{SecureRandom.urlsafe_base64.to_s}".downcase until Brand.where(path: self.path).blank?
    self.path.downcase!
  end

  def normalize_name
    self.name = self.name.downcase.squish
  end

  def remove_logo
    self.logo = self.delete_logo = nil unless self.delete_logo.nil?
  end
end
