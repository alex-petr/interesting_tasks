# == Schema Information
#
# Table name: coupon_discount_types
#
#  id         :integer          not null, primary key
#  name       :string
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe CouponDiscountType, type: :model do
  describe 'Associations' do
    it 'has one :coupon' do
      association = described_class.reflect_on_association(:coupon).macro
      expect(association).to eq :has_one
    end
  end

  describe 'Validations' do
    it 'is valid with :name, :key' do
      expect(create :coupon_discount_type).to be_valid
    end

    it 'is not valid without a :name' do
      expect(build :coupon_discount_type, name: nil).not_to be_valid
    end

    it 'is not valid without a :key' do
      expect(build :coupon_discount_type, key: nil).not_to be_valid
    end

    it 'is not valid with unique :name, :key' do
      coupon_discount_types = [create(:test_coupon_discount_type), build(:test_coupon_discount_type)]

      # Disallow to create duplicating coupon discount types.
      expect(coupon_discount_types.first).to be_valid
      expect(coupon_discount_types.last).not_to be_valid
      expect(coupon_discount_types.last.errors[:name]).not_to be_empty
      expect(coupon_discount_types.last.errors[:key]).not_to be_empty
    end
  end
end
