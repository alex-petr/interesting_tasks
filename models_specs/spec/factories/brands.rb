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

FactoryGirl.define do
  factory :brand do
    name { FFaker::Product.brand }
  end

  factory :adidas_brand, class: Brand do
    name 'Adidas'
  end
end
