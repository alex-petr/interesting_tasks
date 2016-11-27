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

require 'rails_helper'

RSpec.describe Brand, type: :model do
  describe 'Associations' do
    it 'has many :category_brands' do
      association = described_class.reflect_on_association(:category_brands).macro
      expect(association).to eq :has_many
    end

    it 'has many :categories through :category_brands' do
      association = described_class.reflect_on_association(:categories)
      expect(association.macro).to eq :has_many
      expect(association.through_reflection.name).to eq :category_brands
    end

    it 'has many :categories destroy dependency' do

      # mock category sweeper
      category_sweeper = CategorySweeper.instance
      expect(category_sweeper).to receive(:after_save)

      category, brand = create(:category), create(:brand)

      category.brands << Brand.where(id: brand.id)

      # Test for :category_brands associations creation.
      expect(CategoryBrand.count).to eq 1

      brand.destroy

      # After brand deletion all connected :category_brands must be deleted too.
      expect(CategoryBrand.count).to eq 0
    end
  end

  describe 'Validations' do
    it 'is valid with :name' do
      expect(create :brand).to be_valid
    end

    it 'is not valid without a :name' do
      expect(build :brand, name: '').not_to be_valid
    end

    it 'is not valid without unique :name, :path' do
      brands = [create(:adidas_brand), build(:adidas_brand)]

      # Disallow to create duplicating brands.
      expect(brands.first).to be_valid
      expect(brands.last).not_to be_valid
    end
  end

  describe 'Instance methods' do
    it '#normalize_name - downcase and remove all whitespaces on both ends' do
      expect(create(:brand, name: ' ADIDAS ').name).to eq 'adidas'
    end

    it '#process_path - create path URI from name' do
      brands = [create(:brand, name: '!@^&*()_-+ADI DAS#$%'), build(:brand, name: '!@^&*()_-+adi das#$%')]
      brands.each(&:validate)

      # Error-free generation.
      expect(brands.first.errors[:path]).to be_empty
      expect(brands.last.errors[:path]).to be_empty

      # Path should be not empty.
      expect(brands.first.path).not_to be_empty
      expect(brands.last.path).not_to be_empty

      # Check generation correctness.
      expect(brands.first.path).to eq 'adi-das'

      # Path should be uniqueness.
      expect(brands.last.path).not_to eq brands.first.path
      # First path: "adi-das", second is first with random salt: "adi-das-9rxmbxbch_znz72amg9y_q".
      expect(brands.last.path.include? brands.first.path).to be_truthy
      expect(brands.last.path.size).to be > brands.first.path.size
    end
  end
end
