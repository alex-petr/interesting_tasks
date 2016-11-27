# == Schema Information
#
# Table name: categories
#
#  id                     :integer          not null, primary key
#  name                   :string
#  name_eng               :string
#  path                   :string
#  parent_id              :integer
#  lft                    :integer          not null
#  rgt                    :integer          not null
#  depth                  :integer          default(0), not null
#  children_count         :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  menu_class             :string
#  seo_text_footer        :text
#  seo_text_header        :text
#  market                 :boolean          default(FALSE), not null
#  title                  :string
#  description            :text
#  keywords               :text
#  product_list_parsed_at :datetime
#  products_parsed_at     :datetime
#  products_compared_at   :datetime
#  prioritized            :boolean          default(FALSE), not null
#  products_count         :integer          default(0), not null
#
# Indexes
#
#  index_categories_on_lft        (lft)
#  index_categories_on_parent_id  (parent_id)
#  index_categories_on_rgt        (rgt)
#

class Category < ActiveRecord::Base
  include TheSortableTree::Scopes

  ##
  # Constants
  ALLOWED = ' 1234567890qwertyuiopasdfghjklzxcvbnmกขคฆจฉชฌตฏฐฑฒถทธปผพภบฎดซศษสฟฝหฮลฬรยญวอนณมงเแไโใ๑๒๓๔๕๖๗๘๙๐QWERTYUIOPLKJHGFDSAZXCVBNM'

  ##
  # Association macros
  has_many :categories_products, dependent: :destroy
  has_many :products, through: :categories_products

  has_many :category_donor_categories
  has_many :donor_categories, through: :category_donor_categories

  has_many :category_brands
  has_many :brands, through: :category_brands, dependent: :destroy

  has_many :banners_categories
  has_many :banners, through: :banners_categories

  ##
  # Validation macros
  validates_presence_of :name, :name_eng
  validates_uniqueness_of :name, :path

  ##
  #  Callbacks
  before_save :process_path, if: 'name_eng_changed?'

  ##
  # Other macros
  acts_as_nested_set

  ##
  # Public class methods

  def process_path
    path = ''
    self.name_eng.each_char {|c| path << c if Category::ALLOWED.include?(c)}
    self.path = path.squish.gsub(/ /, '-').downcase

    while self.invalid? && !self.errors[:path].empty?
      self.path = "#{self.path}-#{SecureRandom.urlsafe_base64.to_s}"
    end
  end

  def self.collection_to_json(collection = roots)
    collection.inject([]) do |arr, model|
      arr << { id: model.id, content: model.name, children: collection_to_json(model.children) }
    end
  end
end
