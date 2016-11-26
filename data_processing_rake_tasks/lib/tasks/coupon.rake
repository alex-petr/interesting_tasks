namespace :coupon do
  # TODO: It should be run once!
  desc 'Update existing coupons: replace `Brand --> Donor` where `Donor = nil`'
  task :migrate_brand_2_donor => :environment do
    coupon_parser = CouponParser.new
    Coupon.where(donor: nil).each do |coupon|
      brand_name = coupon.brand.name
      donor = coupon_parser.get_donor(brand_name)

      if donor.nil?
        status = "\e[31;1mskipped\e[0m"
      else
        status = "\e[32;1mupdated\e[0m \e[34;1m`donor_id: #{donor.id}, brand: nil\e[0m`"
        coupon.update(donor: donor)
      end
      puts "#{'-' * 80}\n\e[34;1m[INFO]\e[0m Coupon: id = \e[34;1m#{coupon.id}\e[0m, Brand: \e[34;1m#{
           brand_name}\e[0m #{status}"
    end
  end

  desc 'Clear outdated coupons'
  task clear: :environment do
    Coupon.find_each do |coupon|
      if Time.zone.now.utc > coupon.expires_at.utc
        puts "\e[34;1m[INFO]\e[0m Coupon: id = \e[32;1m#{coupon.id}\e[0m \e[31;1mdeleted\e[0m"
        coupon.destroy
      end
    end
  end

  # TODO: It should be run once!
  desc 'Set discount type for coupons'
  task set_discount_type: :environment do
    # Get all coupons without discount type.
    coupons_to_process = Coupon.where(coupon_discount_type_id: nil)
    if coupons_to_process.count > 0
      process_time = Benchmark.realtime do
        puts "\e[34;1m[INFO]\e[0m Found coupons without discount type, processing..."

        # Get coupons ids that have coupon types = special discount.
        special_discount_ids = CouponCouponType.select(:coupon_id).group(:coupon_id).map(&:coupon_id)

        # Get coupons ids that don't have coupon types = percent discount.
        percent_discount_ids = coupons_to_process.map(&:id) - special_discount_ids

        # Update special discount type.
        Coupon.where(id: special_discount_ids)
          .update_all(coupon_discount_type_id: CouponDiscountType.find_by_key(:special).id)

        # Update percent discount type.
        Coupon.where(id: percent_discount_ids)
          .update_all(coupon_discount_type_id: CouponDiscountType.find_by_key(:percent).id)

        puts "\e[34;1m[INFO]\e[0m Set \e[32;1m#{special_discount_ids.count}\e[0m coupons of special discount type."
        puts "\e[34;1m[INFO]\e[0m Set \e[32;1m#{percent_discount_ids.count}\e[0m coupons of percent discount type."
      end
      puts "#{'-' * 80}\n\e[34;1m[INFO]\e[0m Coupons discount type processed for: \e[32;1m#{process_time.round(3)
           }\e[0m seconds"
    end
  end

  desc 'Process coupons url: replace coupons url by brand/donor destination url'
  task process_url: [:environment, :set_discount_type] do
    coupon_parser = CouponParser.new
    process_time = Benchmark.realtime do
      Coupon.find_each do |coupon|
        puts "#{'-' * 80}\n\e[34;1m[INFO]\e[0m Process coupon: id = \e[32;1m#{coupon.id}\e[0m"
        processed_url = coupon_parser.process_url coupon.url
        if processed_url != coupon.url && !processed_url.blank?
          if coupon.update(url: processed_url)
            puts "\e[34;1m[INFO]\e[0m Url \e[32;1mprocessed:\e[0m \e[34;1m#{processed_url}\e[0m"
          else
            puts "\e[31;1m[ERROR]\e[0m \e[31;1mDuring updating url:\e[0m \e[34;1m#{coupon.url}\e[0m"
            ap coupon.errors
          end
        else
          puts "\e[34;1m[INFO]\e[0m Url \e[31;1mskipped:\e[0m \e[34;1m#{coupon.url}\e[0m"
        end
      end
    end
    puts "\n#{'-' * 80}\n\e[34;1m[INFO]\e[0m Coupons url processed for: \e[32;1m#{process_time.round(3)}\e[0m seconds"
  end
end
