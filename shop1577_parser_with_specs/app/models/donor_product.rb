# == Schema Information
#
# Table name: donor_products
#
#  id          :integer          not null, primary key
#  donor_id    :integer
#  path        :string
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  brand_id    :integer
#  seller_id   :integer
#  price       :decimal(12, 2)
#  saving      :string
#  image_url   :string
#  description :text
#  old_price   :decimal(12, 2)
#  expired     :boolean          default(FALSE), not null
#  auto_brand  :boolean          default(FALSE), not null
#  matched     :boolean          default(FALSE)
#
# Indexes
#
#  index_donor_products_on_donor_id_and_path  (donor_id,path)
#

class DonorProduct < ActiveRecord::Base
  include ProductConnectable
  # fuzzily_searchable :name, :price

  has_many :donor_categories_donor_products
  has_many :donor_categories, through: :donor_categories_donor_products
  has_many :donor_products_specification_values, dependent: :destroy
  has_many :donor_product_images, dependent: :destroy
  has_many :product_donor_products
  has_many :products, through: :product_donor_products
  belongs_to :donor
  belongs_to :seller
  belongs_to :brand

  validates :path, presence: true, uniqueness: {scope: :donor_id}

  before_save :process_prices
  after_update :update_price_and_discount

  after_commit :fetch_details, if: :persisted?

  def update_price_and_discount
    # call update_price_and_discount for each connected product
    self.products.each{|product| product.update_price_and_discount}
  end

  def process_prices
    if (self.old_price.blank? || self.old_price.zero?) && !self.saving.blank?
      # calculate old price by discount
       if self.saving.to_i == 100
         self.old_price = nil
       else
         self.old_price = (100 * self.price / (100 - self.saving.to_i)).to_i
       end
    elsif !self.old_price.blank? && !self.old_price.zero? && self.saving.blank?
      # calculate by discount by old_price
      self.saving = 100 - ((self.price * 100) / self.old_price).to_i
    end
  end

  def calc_old_price
    if !self.old_price.blank? && !self.old_price.zero?
      self.old_price
    elsif (self.old_price.blank? || self.old_price.zero?) && !self.saving.blank? && self.saving.to_i != 100
      (100 * self.price / (100 - self.saving.to_i)).to_i
    else
      0.0
    end
  end

  def mark_expired
    self.expired = true
    self.save
  end

  def mark_unexpired
    self.expired = false
    self.save
  end

  def url
    "#{self.donor.url}#{self.path}"
  end

  def logo_path(style)
    !self.seller.blank? && self.seller.logo.exists? ? self.seller.logo(style) : self.donor.logo(style)
  end

  def fetch_details
    # TODO enable later - if problem with non existant products solved
    DonorProductParseWorker.perform_in(1.minutes, self.id) if self.description.nil?
  end

  def specifications
    dpsv = DonorProductsSpecificationValue.where(donor_product_id: self.id)
    sv = SpecificationValue.where(id: dpsv.map(&:specification_value_id))
    sv.map do |value|
      { name: Specification.find(value.specification_id).name, value: value.name }
    end
  end

end
