# == Schema Information
#
# Table name: coupons
#
#  id                      :integer          not null, primary key
#  brand_id                :integer
#  seller_id               :integer
#  name                    :string
#  code                    :string
#  discount                :integer
#  description             :string
#  approved                :boolean          default(FALSE), not null
#  expires_at              :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  moderated               :boolean          default(FALSE), not null
#  url                     :text
#  uses_count              :integer          default(0), not null
#  home_page               :boolean          default(FALSE), not null
#  coupon_page             :boolean          default(FALSE), not null
#  donor_id                :integer
#  default_logo            :boolean          default(FALSE), not null
#  coupon_discount_type_id :integer
#  promotional             :boolean          default(TRUE), not null
#  coupon_image_id         :integer
#
# Indexes
#
#  index_coupons_on_coupon_image_id  (coupon_image_id)
#

require 'rails_helper'

RSpec.describe Coupon, type: :model do
  describe 'Associations' do
    it 'belongs to :coupon_discount_type' do
      association = described_class.reflect_on_association(:coupon_discount_type).macro
      expect(association).to eq :belongs_to
    end
  end

  describe 'Validations' do
    it 'is valid with :brand_id, :seller_id, :coupon_discount_type_id, :name, :code, :discount, :description,'\
       ':expires_at' do
      expect(create :coupon).to be_valid
    end

    it 'is not valid without a :brand_id' do
      expect(build :coupon, brand_id: nil).not_to be_valid
    end

    it 'is not valid without a :seller_id' do
      expect(build :coupon, seller_id: nil).not_to be_valid
    end

    it 'is not valid without a :coupon_discount_type_id' do
      expect(build :coupon, coupon_discount_type_id: nil).not_to be_valid
    end

    it 'is not valid without a :name' do
      expect(build :coupon, name: nil).not_to be_valid
    end

    it 'is not valid without a :code' do
      expect(build :coupon, code: nil).not_to be_valid
    end

    it 'is not valid without a :discount' do
      expect(build :coupon, discount: nil).not_to be_valid
    end

    it 'is not valid without a :description' do
      expect(build :coupon, description: nil).not_to be_valid
    end

    it 'is not valid without a :expires_at' do
      expect(build :coupon, expires_at: nil).not_to be_valid
    end

    it 'is not valid without a :brand_id only integer numericality' do
      expect(build :coupon, brand_id: 'test').not_to be_valid
    end

    it 'is not valid without a :seller_id only integer numericality' do
      expect(build :coupon, seller_id: 'test').not_to be_valid
    end

    it 'is not valid without a :coupon_discount_type_id only integer numericality' do
      expect(build :coupon, coupon_discount_type_id: 'test').not_to be_valid
    end

    it 'is not valid without a :discount only integer numericality' do
      expect(build :coupon, discount: 'test').not_to be_valid
    end

    it 'is not valid without a :uses_count only integer numericality' do
      expect(build :coupon, uses_count: 'test').not_to be_valid
    end

    it 'is not valid with unique :code' do
      coupons = [create(:test_coupon), build(:test_coupon)]

      # Disallow to create duplicating coupons.
      expect(coupons.first).to be_valid
      expect(coupons.last).not_to be_valid
      expect(coupons.last.errors[:code]).not_to be_empty
    end
  end
end
