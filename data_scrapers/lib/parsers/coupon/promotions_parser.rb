# TODO Refactor, using only status-publish - make code shorter

class PromotionsParser < CouponParser
  def parse_store(category)
    coupons_created = 0
    coupons_existing = 0
    page_url = "http://#{@coupon_donor.domain}/coupon/stores/"

    doc = get_page_html(page_url)
    return if doc.nil?

    coupon_store_links = doc.css('ul.stores > li > a').map { |node| { url: node[:href], name: node.text.squish } }

    coupon_store_links.each do |store_link|
      doc = get_page_html(store_link[:url])
      next if doc.nil?

      no_links_css = 'div.head:has(h2:contains("Active Coupons")) + div.blog > h3:contains("Sorry, no coupons found")'
      next if doc.at_css(no_links_css).present?

      coupons_node_css = 'div.box-holder:has(div.head > h2:contains("Active Coupons")) > div.item.coupon'
      doc.css(coupons_node_css).each do |coupon_node|
        coupon_url = coupon_node.at_css('h3 > a')[:href]
        coupon_page = get_page_html(coupon_url)
        next if coupon_page.nil?

        params = {
          brand_id: nil,
          seller_id: get_seller_id(store_link[:name]),
          name: get_coupon_name(coupon_page),
          code: get_coupon_code(coupon_page),
          discount: 0,
          description: get_description(coupon_page),
          moderated: true,
          approved: true,
          expires_at: get_date(coupon_page),
          url: coupon_url,
          coupon_page: true,
          coupon_donor_id: @coupon_donor.id,
          coupon_discount_type_id: 1
        }

        ap new_coupon = Coupon.create(params)

        if new_coupon.id.nil?
          coupons_existing += 1
          p "Coupons created: #{coupons_created}"
          p "Existing coupons: #{coupons_existing}"
        else
          coupons_created += 1
          p "Coupons created: #{coupons_created}"
          p "Existing coupons: #{coupons_existing}"
        end
      end
    end
  end

  private

  def get_seller_id(seller_name)
		seller_name.downcase!
    seller = Seller.find_by("url LIKE ?", "%#{seller_name}")
    return seller.id if seller.present?

    Seller.create(name: seller_name, url: seller_name).id
  end

  def get_coupon_name(node)
    node.at_css('a[id*="coupon-link"]')['data-clipboard-text']
  end

  def get_coupon_code(node)
    node.at_css('div.link-holder > a')['data-clipboard-text']
  end

	def get_description(coupon_page)
		coupon_page.css('div:has(h2:contains("Coupon Details")) > p').text.squish
	end

	def get_date(coupon_page)
		date_strings = coupon_page.css('div.content-bar > p.meta').text.squish.scan(/\w+\s+\d+,\s+\d{4}/)
		return if date_strings.empty?

    date_strings.map { |date_str| Date.parse(date_str) }.max
	end

  def get_page_html(url, method = :get, query = {})
    page_html = {}
    tryouts = 0

    begin
      tryouts += 1

      # Get page html
      page = (method == :post) ? @agent.post(url, query) : @agent.get(url)

    rescue Mechanize::Error => error

      if tryouts < 3
        display_info("Retry request \e[33;1m#{tryouts}\e[0m time...")
        retry
      else
        return
      end

    rescue Timeout::Error => error
      display_error("\e[34;1mTimeout expired\e[0m \e[31;1m#{error.message}\e[0m")

    rescue Exception => error
      display_error("\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m")

    else # Handle response codes: 200, 301, 302

      if page.code[/200/]
        page_html = Nokogiri::HTML(page.body)

      elsif page.code[/30[12]/] # 301, 302 redirects
        display_http_error(code: page.code, url: url)
        display_info("Follow redirect --> \e[34;1m#{page.header['location']}\e[0m")
        return get_page_html(page.header['location']) # Follow redirect

      else # Unexpected response code
        display_http_error(code: page.code, url: url)
      end

    ensure

      page_html
    end
  end
end
