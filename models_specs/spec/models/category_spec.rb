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

require 'rails_helper'

RSpec.describe Category, type: :model do

  describe 'Associations' do
    it 'has many :category_brands' do
      association = described_class.reflect_on_association(:category_brands).macro
      expect(association).to eq :has_many
    end

    it 'has many :brands through :category_brands' do
      association = described_class.reflect_on_association(:brands)
      expect(association.macro).to eq :has_many
      expect(association.through_reflection.name).to eq :category_brands
    end

    it 'has many :brands destroy dependency' do
      # mock category sweeper
      category_sweeper = CategorySweeper.instance
      expect(category_sweeper).to receive(:after_save)
      expect(category_sweeper).to receive(:after_destroy)

      category, brands  = create(:category), 2.times.map { create :brand }

      category.brands << Brand.where(id: [brands.first.id, brands.last.id])

      # Test for :category_brands associations creation.
      expect(CategoryBrand.count).to eq 2

      category.destroy

      # After category deletion all connected :category_brands must be deleted too.
      expect(CategoryBrand.count).to eq 0
    end
  end

  describe 'Validations' do
    it 'is valid with :name, :name_eng' do
      # mock category sweeper
      category_sweeper = CategorySweeper.instance
      expect(category_sweeper).to receive(:after_save)

      expect(create :category).to be_valid
    end

    it 'is not valid without a :name' do
      expect(subject).not_to be_valid
    end

    it 'is not valid without a :name_eng' do
      subject.name = 'โน๊ตบุ๊ค'
      expect(subject).not_to be_valid
    end

    it 'is not valid without unique :name, :name_eng' do
      # mock category sweeper
      category_sweeper = CategorySweeper.instance
      expect(category_sweeper).to receive(:after_save)

      categories = [create(:notebook_category), build(:notebook_category)]

      # Disallow to create duplicating categories.
      expect(categories.first).to be_valid
      expect(categories.last).not_to be_valid
    end
  end
end
