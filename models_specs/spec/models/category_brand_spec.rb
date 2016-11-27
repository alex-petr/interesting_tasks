# == Schema Information
#
# Table name: category_brands
#
#  id          :integer          not null, primary key
#  category_id :integer
#  brand_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe CategoryBrand, type: :model do
  describe 'Associations' do
    it 'belongs to :category' do
      association = described_class.reflect_on_association(:category).macro
      expect(association).to eq :belongs_to
    end

    it 'belongs to :brand' do
      association = described_class.reflect_on_association(:brand).macro
      expect(association).to eq :belongs_to
    end
  end

  describe 'Validations' do
    it 'is not valid without unique :brand_id in :category_id scope' do
      # mock category sweeper
      category_sweeper = CategorySweeper.instance
      expect(category_sweeper).to receive(:after_save)

      category, brands  = create(:category), 2.times.map { create :brand }

      category.brands << Brand.where(id: [brands.first.id, brands.last.id])

      # Test for :category_brands associations creation.
      expect(CategoryBrand.count).to eq 2

      # Try to add same brands to category.
      begin
        category.brands << Brand.where(id: [brands.first.id, brands.last.id])
      rescue Exception => error
        # Which cause `Validation failed: Brand has already been taken` error.
        expect(error.class.to_s).to eq 'ActiveRecord::RecordInvalid'
      end

      # Count of :category_brands associations must still same.
      expect(CategoryBrand.count).to eq 2
    end
  end
end
