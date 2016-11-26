namespace :brand do
  # TODO: It should be run once!
  desc 'Remove duplicated brands: merge several into one'
  task merge: :environment do
    puts "Total brands count: #{Brand.count}"
    process_time = Benchmark.realtime do
      caption = "\rBrand path is processed: "
      # 1. Get all duplications list.
      Brand.select('path, COUNT(*) as counter').group('path').having('COUNT(*) > 1').map do |brand|
        # 2. Get duplications with same path.
        main_brand       = Brand.where(path: brand.path).first
        brands_to_delete = Brand.where(path: brand.path).where.not(id: main_brand.id)
        # 3. Get first brand as main.
        print "#{caption}#{' ' * 80}#{caption}#{brand.path}"
        # 4. Move all products/coupons from others brands to main.
        brands_to_delete.each do |brand_to_delete|
          [DonorProduct, Product, Coupon].each do |obj|
            obj.where(brand_id: brand_to_delete.id).update_all(brand_id: main_brand.id)
          end
        end
        # 5. Delete all except main brand.
        brands_to_delete.destroy_all
      end
    end
    puts "\nTime taken for brands processing: #{process_time.round(3)} seconds"
  end

  # TODO: It should be run once!
  desc 'Normalize brand names: run Brand#normalize_name'
  task normalize_name: :environment do
    process_time = Benchmark.realtime do
      caption = "\rBrand is processed: "
      Brand.find_each do |brand|
        print "#{caption}#{' ' * 80}#{caption}#{brand.name}"
        brand.update(name: brand.normalize_name) # self.name = self.name.downcase.squish
      end
    end
    puts "\nTime taken for brands processing: #{process_time.round(3)} seconds"
  end
end
