require 'capybara/poltergeist'
# TODO: Add discount in RP
# TODO Seller?

class IpriceParser < CouponParser
  def parse_store(category)
    index = 1
    initialize_capybara
    run_headless do
      page_url = "https://#{@coupon_donor.domain}/coupons/stores/"

      doc = get_page_html(page_url)
      store_nodes = doc.css('div.coupon-store-item p').map { |node| { name: node[:title], url: node.at_css('a')[:href] } }

      store_nodes.each do |store_node|
        params = {}
        load_page store_node[:url]
        next if @browser.has_no_css?('article.coupon')

        coupons_size = @browser.all("article.coupon").size
        coupons_size.times do |time|
          load_page store_node[:url]
          coupon = @browser.all("article.coupon")[time]
          next if coupon[:class].include?('expired')

          next if coupon.first(:xpath, "./div[@class='details-toggle']").nil?

          coupon.find(:xpath, "./div[@class='details-toggle']").click
          name = coupon.find('div.name').text

          params = {
            brand_id: nil,
            discount: get_discount(time),
            name: get_coupon_name(coupon),
            description: get_coupon_name(coupon),
            seller_id: get_seller_id(coupon, store_node[:name]),
            url: nil,
            coupon_page: true,
            moderated: true,
            approved: true,
            coupon_donor_id: @coupon_donor.id,
            coupon_discount_type_id: get_discount_type(time)
          }
          params[:expires_at] = try_parse_datetime(coupon.first("div.fields > div").text)
          next if params[:expires_at].nil?

          code = get_code(coupon)
          begin
            @browser.windows.each { |window| window.close }
          rescue
            retry
          end
          params[:code] = code
          ap x = Coupon.find_or_create_by(params)
          ap "Store name: #{store_node[:name]}"

          STDOUT.write "\r\e[31;1m Updated: #{index}\e[0m"
          index += 1
        end
      end
    end
  end

  private

  def get_code(coupon)
    coupon.find('div.name').click
    new_window=@browser.driver.browser.window_handles.last
    code = nil
    @browser.within_window(new_window) do
      until(@browser.first('span#code').nil? || @browser.first('span.nocode-text-cell').nil?) do end
      code = @browser.first('span#code').try(:text)
      code = @browser.first('span.nocode-text-cell').try(:text) if code.nil?

      @browser.execute_script "window.close();"
    end
    return if code == "Kode tidak diperlukan" || code == 'ไม่มีโค้ดคูปอง'

    code
  end

  def prepare_to_parse(doc)
    doc.css('div.store-list/ul/li/a').each do |link|
      name = link.text.squish
      url = link[:href]
      brand = Brand.find_by("name ILIKE ?", name)
      brand = Brand.create(name: name) if brand.nil?
      store = CouponStore.find_or_create_by(name: name, brand_id: brand.id, donor_id: @coupon_donor.id)
      CouponDonorCouponStore.find_or_create_by(coupon_donor_id: @coupon_donor.id,
                                               coupon_store_id: store.id,
                                               store_url: url)
    end
  end

  def try_parse_datetime(str)
    str.to_datetime
  rescue ArgumentError => e
    return if e.message == 'invalid date'
  end

  def get_discount(time)
    discount = @browser.all('div.offer-text')[time].text
    if discount.include?('%')
      discount.to_i
    elsif discount.include?('Rp')
      discount.gsub!('Rp', '')
      if discount.include?('k')
        discount.to_i * 1000
      else
        discount.to_i
      end
    else
      1
    end
  end

  def get_discount_type(time)
    discount = @browser.all('div.offer-text')[time].text
    if discount.include?('%')
      CouponDiscountType.find_by_key('percent').id
    elsif discount.include?('Rp')
      CouponDiscountType.find_by_key('amount').id
    else
      CouponDiscountType.find_by_key('special').id
    end
  end

  def get_page_html(url, method = :get, query = {})
    page_html = {}
    tryouts = 0

    begin
      tryouts += 1

      # Get page html
      page = (method == :post) ? @agent.post(url, query) : @agent.get(url)

    rescue Mechanize::Error => error
      # Currently, this exception will be thrown if Mechanize encounters response codes other than 200, 301, or 302.
      display_http_error(code: error.response_code, url: url)

      if !error.response_code[/404/] && tryouts < 3
        display_info("Retry request \e[33;1m#{tryouts}\e[0m time...")
        retry
      end

    rescue Timeout::Error => error
      display_error("\e[34;1mTimeout expired\e[0m \e[31;1m#{error.message}\e[0m")

    rescue Net::HTTP::Persistent::Error => error
      display_error("\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m")
      return

    rescue Exception => error
      display_error("\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m")

    else # Handle response codes: 200, 301, 302

      if page.code[/200/]
        page_html = Nokogiri::HTML(page.body)

      elsif page.code[/30[12]/] # 301, 302 redirects
        display_http_error(code: page.code, url: url)

        if redirect_to_non_product_page?(page.header['location'])
          return nil
        else
          display_info("Follow redirect --> \e[34;1m#{page.header['location']}\e[0m")
          return get_page_html(page.header['location'])
        end

      else # Unexpected response code
        display_http_error(code: page.code, url: url)
      end

    ensure
      page_html
    end
  end

  def get_seller_id(coupon, seller_name)
		seller_name.downcase!
    url_node = coupon.first('div.holder > div.action > a')
    if url_node.nil?
      seller = Seller.find_by(name: seller_name)
      return seller.id if seller.present?

      return Seller.create(name: seller_name, url: seller_name).id
    end

    seller_name.gsub!(' ', '-')
    seller_name.gsub!('!', '')
    seller_url = url_node[:onclick][/#{seller_name}\",\s+\"(.+)\"/, 1]

    seller_url = url_node[:onclick][/\"(.{1,5}#{seller_name})/, 1] if seller_url.nil?

    seller = Seller.find_by("url LIKE ?", "%#{seller_url}")
    return seller.id if seller.present?

    Seller.create(name: seller_name, url: seller_url).id
  end

  def get_coupon_name(node)
    node.find('div.name').text
  end
end
