# == Schema Information
#
# Table name: donor_categories
#
#  id                          :integer          not null, primary key
#  donor_id                    :integer
#  parent_id                   :integer
#  lft                         :integer          not null
#  rgt                         :integer          not null
#  depth                       :integer          default(0), not null
#  children_count              :integer          default(0), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  name                        :string
#  name_eng                    :string
#  path                        :string
#  alternate_url               :string
#  active                      :boolean          default(TRUE)
#  product_parsing_started_at  :datetime
#  product_parsing_finished_at :datetime
#  products_per_page           :integer
#  last_parsed_page_number     :integer
#  last_known_page_number      :integer
#  expected_number_of_products :integer
#
# Indexes
#
#  index_donor_categories_on_lft        (lft)
#  index_donor_categories_on_parent_id  (parent_id)
#  index_donor_categories_on_rgt        (rgt)
#

class DonorCategory < ActiveRecord::Base
  acts_as_nested_set scope: :donor
  include RenderNestedOptionsHelper
  include TheSortableTree::Scopes

  has_many :donor_categories_donor_products, dependent: :destroy
  has_many :donor_products, through: :donor_categories_donor_products
  has_many :category_donor_categories, dependent: :destroy
  has_many :categories, through: :category_donor_categories

  belongs_to :donor

  validates :path, uniqueness: {scope: :donor_id, allow_nil: true}

  after_create :market_category_check

  # if donor_category belongs to market-donor we should automatically connect it to market-category
  def market_category_check
    if self.donor.market?
      # search for market-category
      market_category = Category.where(market: true).first

      return if market_category.nil?

      # link donor_category to market category
      self.categories << market_category
    end
  end

  def safe_destroy
    unless self.leaf?
      Chewy.strategy(:sidekiq)
      self.update({active: false})
      return false
    end
    Chewy.strategy(:sidekiq)
    self.destroy
  end

  def url
    "#{self.donor.url}#{self.path}"
  end

  def all_pages_scrapped?
    !self.last_parsed_page_number.blank? && self.last_parsed_page_number == self.last_known_page_number
  end

end
