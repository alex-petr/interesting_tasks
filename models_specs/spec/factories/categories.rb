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

FactoryGirl.define do
  factory :category do
    name     { FFaker::Product.product_name }
    name_eng { FFaker::Product.product_name }
  end

  factory :market_category, class: Category do
    name { FFaker::Product.product_name }
    name_eng { FFaker::Product.product_name }
    parent nil
    market true
  end

  factory :notebook_category, class: Category do
    name     'โน๊ตบุ๊ค'
    name_eng 'Notebook'
  end

end
