# == Schema Information
#
# Table name: donors
#
#  id                     :integer          not null, primary key
#  domain                 :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  parser_class           :string
#  cookie_set_url         :string
#  landing_page_params    :text
#  product_list_parsed_at :datetime
#  products_parsed_at     :datetime
#  products_compared_at   :datetime
#  market                 :boolean          default(FALSE), not null
#  product_domain         :string
#  disabled               :boolean          default(FALSE), not null
#  logo_file_name         :string
#  logo_content_type      :string
#  logo_file_size         :integer
#  logo_updated_at        :datetime
#  custom                 :boolean          default(FALSE), not null
#  protocol               :integer          default(0), not null
#

class Donor < ActiveRecord::Base
  has_many :donor_categories
  has_many :donor_products

  attr_accessor :delete_logo

  enum protocol: [:http, :https]

  has_attached_file :logo,
                    styles: { large: '380x240>', thumb: '120x30#' },
                    processors: [:thumbnail, :paperclip_optimizer],
                    default_url: '/images/:style/missing.png'
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/

  validates :domain, presence: true, uniqueness: true
  validates :parser_class, presence: true

  default_scope { where(custom: false) }

  scope :nonmarket, -> { where(market: false) }
  scope :market,    -> { where(market: true)  }
  scope :disabled,  -> { where(disabled: true)  }
  scope :enabled,   -> { where(disabled: false) }

  before_update :remove_logo
  before_create :set_dates, :set_product_domain

  def url
    "#{protocol}://#{domain}"
  end

  def is_affiliate?
    cookie_set_url.present? # TODO: probably add `landing_page_params` to condition in future.
  end

  private

  def remove_logo
    self.logo = self.delete_logo = nil unless self.delete_logo.nil?
  end

  def set_product_domain
    self.product_domain ||= domain
  end

  def set_dates
    past_date = Time.now - 15.days
    self.product_list_parsed_at ||= past_date
    self.products_parsed_at ||= past_date
    self.products_compared_at ||= past_date
  end

end
