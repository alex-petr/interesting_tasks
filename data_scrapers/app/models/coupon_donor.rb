# == Schema Information
#
# Table name: coupon_donors
#
#  id           :integer          not null, primary key
#  domain       :string           not null
#  parser_class :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class CouponDonor < ActiveRecord::Base
end
