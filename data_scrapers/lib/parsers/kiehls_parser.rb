##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.kiehls.co.th domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class KiehlsParser < Parser

  PRICE_CSS_SELECTOR = { old_price: nil, price: '.product-info-box .price-box span.price' }
  # Parsing methods ####################################################################################################

  def initialize(*args)
    @product_selector = {
      price: PRICE_CSS_SELECTOR,
      name: '.product-info-box h1',
      images: '.MagicToolboxSelectorsContainer a',
      images_attr: :href,
      description: '.product-info-box .short-description .std, .product-info-box .box-description .std'
    }

    initialize_capybara(false)
    @products_iterator_selector = 'li.item'
    super
  end

  # Parse categories structure
  def parse_category_tree
    page_html = get_page_html "#{@donor.url}/?___store=#{@lang}"

    # Skip: ["Offers", "What's New"] Parse: ["Skin Care", "Body", "Men", "Hair"] Skip: ["Gift & More", "About Us"]
    page_html.css('#mobile-menu li.level0').slice(2...-2).each do |parent_category|
      parent_category_link = get_link(parent_category.at_css('a'))
      next if parent_category_link[:name].empty? && parent_category_link[:path].empty?
      category_parent = save_category(parent_category_link)
      display_category_structure(parent_category_link, "#{'=' * 36} [INFO] #{'=' * 36}\n", "\n#{'-' * 80}")
      # First level subcategories
      parent_category.css('li.level1 a').each do |subcategory_first_level|
        subcategory_first_level_link = get_link(subcategory_first_level)
        save_category(subcategory_first_level_link, category_parent.id)
        display_category_structure(subcategory_first_level_link, ' ' * 2)
      end if parent_category
    end if page_html
  end

  def parse_category_products(donor_category_id = nil)
    run_headless do
      super(donor_category_id)
    end
  end

  def parse_category(donor_category)
    page_num = page_to_parse(donor_category)
    next_page = true
    iterator = 1
    products_on_page = 0
    arr = []

    category_logger = ParserSupport::CategoryLogger.new(donor_category)

    # update category «products_parsed_at» date
    donor_category.touch(:product_parsing_started_at)

    while next_page do
      page_url = "#{donor_category.url}?p=#{page_num}"

      load_page(page_url)
			puts "Page url: #{page_url}"

      if @browser.nil?
        category_logger.donor_category_pages_log.warn("#{Time.zone.now} NIL returned instead of browser #{page_url}")
        next_page = false
        next
      end

      category_logger.donor_category_pages_log.info("#{Time.zone.now} [200] Got some data from page #{page_url}")

      @browser.all(@products_iterator_selector).each do |donor_product_node|
        donor_product_data = parse_donor_product_block(donor_product_node)

        arr << donor_product_data
        ap donor_product_data

        save_donor_product_link(donor_category.id, donor_product_data)

        products_on_page += 1 if iterator == 1
      end

      if last_page?(@browser, 'li.current + li')
        category_logger.donor_category_pages_log.info("#{Time.zone.now} NO NEXT PAGE LINK on page #{page_url}")
        next_page = false
      end

      update_donor_category_tracking_data(donor_category, page_num, !next_page, products_on_page, iterator)

      page_num += 1
      iterator += 1
    end
  end

  def parse_donor_product_block(donor_product_node)
    path = donor_product_node.first('a')[:href].gsub("#{@donor.url}", '')
    name = donor_product_node.first('h2.product-name').text.squish

    price = get_capybara_float(donor_product_node.first('span.regular-price'))
    price = get_capybara_float(donor_product_node.all('ul.price-box li').first.all('span').last) if price.nil?

    {path: path, price: price, name: name, old_price: nil}
  end

  def parse_product(donor_product)
    params = {}
    load_page(donor_product.url)

    return false if @browser.nil?

    params[:name] = get_capybara_name(@browser.first('.product-info-box h1'))
    params[:price] = get_capybara_float(@browser.first('.product-info-box .price-box span.price'))
    return false if params[:price].nil? || params[:name].nil?

    params[:description] = @browser.find('div.box-collateral.box-description').base.inner_html
		doc = get_page_html(donor_product.url)

    save_gallery(donor_product.id, doc.css('.MagicToolboxSelectorsContainer a'), :href)

    DonorProductUpdateWorker.perform_async(donor_product.id, params) #unless DRY_RUN
  end

  def get_capybara_name(node)
    return if node.nil? || node.text.empty?

    node.text.squish
  end

  def get_capybara_float(node)
    return if node.nil? || node.text.empty?

    node.text[/[\d,]+/].gsub(',', '').to_f
  end

  def last_page?(browser, selector)
    browser.has_no_css?(selector)
  end

  def paginate_substring(page_number)
    "?p=#{page_number}"
  end

  def display_category_structure(category_link, prefix = '', suffix = '')
    puts "#{prefix}-> `#{category_link[:name]}` => `#{category_link[:path]}`#{suffix}"
  end

  def get_link(node)
    { name: get_name(node), path: get_link_path(node[:href]) }
  end
end
