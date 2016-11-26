namespace :weloveshopping do
  # TODO: It should be run once!
  desc 'Add logo to WeLoveShoppingParser sellers'
  task :add_seller_logo => :environment do
    donor = Donor.find_by_parser_class('WeLoveShoppingParser')

    # Get full sellers list for this donor.
    sellers = Seller.
      joins(:donor_products).
      where(donor_products: { donor_id: donor.id }, sellers: { logo_file_name: nil }).
      group(:id)

    # Process and save seller logo.
    sellers.each do |seller|
      seller.logo = WeLoveShoppingParser.new('th').process_seller_logo seller.url
      seller.save
    end
  end

  desc 'Update prices for WeLoveShoppingParser products'
  task update_prices: :environment do
    products_processed         = 1
    product_process_time       =
    product_process_time_total = 0
    donor              = Donor.find_by_parser_class :WeLoveShoppingParser
    parser             = WeLoveShoppingParser.new('th')
    products           = Product.includes(donor_products: :donor).where(donors: {id: donor.id})
    products_count     = products.count

    puts "\e[34;1m[INFO]\e[0m Total products count: \e[32;1m#{products_count}\e[0m"

    products.find_each(batch_size: 300) do |product|
      product.donor_products.each do |donor_product|
        start_time = Time.now

        parser.update_prices_sync(donor_product)

        puts "\e[34;1m[INFO]\e[0m Products processed: \e[32;1m#{products_processed} / #{
          (products_processed * 100.0 / products_count).round 3}%\e[0m"

        products_processed += 1

        end_time = Time.now

        product_process_time = end_time - start_time

        # Time estimate by time spent for processing current product
        # time_left = (products_count - products_processed) * product_process_time

        # More precisely time estimate: by summing up all time spent divided by count processed products
        product_process_time_total += product_process_time
        time_left = (products_count - products_processed) * (product_process_time_total / products_processed)
        puts "\e[34;1m[INFO]\e[0m Approximately time left: \e[32;1m#{
          Time.at(time_left).utc.strftime('%H:%M:%S')}\e[0m\n#{'-' * 80}"
      end
    end
  end
end
