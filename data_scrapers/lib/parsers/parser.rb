class Parser
  require 'open-uri'
  require 'support/category_handler'
  require 'support/donor_product_image_handler'
  require 'support/category_logger'

  include ParserSupport::CategoryHandler
  include ParserSupport::DonorProductImageHandler
  # Cold start: parse & display data without saving/updating anything, must be `false` for production.
  DRY_RUN = Rails.env.development?
  # DRY_RUN = false

  def initialize(*args)
    @donor = Donor.find_by_parser_class(self.class.to_s)
    @agent = init_agent
    # init_logger
    @get_page_logger = ActiveSupport::Logger.new("#{Rails.root}/log/get_page.log")
    @general_logger  = ActiveSupport::Logger.new("#{Rails.root}/log/scrappers/general.log")
  end

  def parse_category_products(donor_category_id =nil)
    # get categories to parse
    donor_categories = donor_categories_to_parse(donor_category_id)

    donor_categories.find_each do |donor_category|
      category_logger = ParserSupport::CategoryLogger.new(donor_category)

      message = "#{Time.zone.now} Starting parse donor category: #{donor_category.id}; path: #{donor_category.path};"
      DRY_RUN ? puts(message) : category_logger.donor_category_pages_log.info(message)

      if donor_category.all_pages_scrapped?
        puts "All pages scrapped"
      else
        parse_category(donor_category)
      end

    end
  end

  def parse_category(donor_category)
    page_num = page_to_parse(donor_category)
    next_page = true
    iterator = 1
    products_on_page = 0

    category_logger = ParserSupport::CategoryLogger.new(donor_category)

    # update category «products_parsed_at» date
    donor_category.touch(:product_parsing_started_at) unless DRY_RUN

    # Parse category page by page, until next page exists
    while next_page
      page_url = get_page_url(donor_category.url, paginate_substring(page_num))

      puts "scraping: #{page_url}"
      doc = get_page_html(page_url)

      if doc.nil?
        category_logger.donor_category_pages_log.warn("#{Time.zone.now} NIL returned instead of page #{page_url}")
        next_page = false
        next
      end

      if doc.blank?
        category_logger.donor_category_pages_log.warn("#{Time.zone.now} {} returned instead of page #{page_url}")
        next
      end

      # save successful tries
      category_logger.donor_category_pages_log.info("#{Time.zone.now} [200] Got some data from page #{page_url}")

      # iterate over product blocks
      # todo separate to method-block or apply selector
      doc.css(@products_iterator_selector).each do |donor_product_node|
        donor_product_data = parse_donor_product_block(donor_product_node)
        DRY_RUN ? ap(donor_product_data) : save_donor_product_link(donor_category.id, donor_product_data)
        products_on_page += 1 if iterator == 1
      end

      puts "Donor products on page: #{doc.css(@products_iterator_selector).size}"

      if check_infinite_loop?
        next_page = false if is_infinite_loop?(doc, page_num)
      end

      # if first page and we have method to get expected products number
      if page_num == 1 && self.respond_to?(:parse_expected_products_number)
        expected_products = parse_expected_products_number(doc)
        donor_category.update(expected_number_of_products: expected_products) unless expected_products.nil?
      end

      if last_page?(doc, page_num)
        message = "#{Time.zone.now} NO NEXT PAGE LINK on page #{page_url}"
        DRY_RUN ? puts(message) : category_logger.donor_category_pages_log.info(message)
        next_page = false
      end

      unless DRY_RUN
        update_donor_category_tracking_data(donor_category, page_num, !next_page, products_on_page, iterator)
      end

      page_num += 1
      iterator += 1
    end
  end



  # update donor_category tracking data (date, page numbers, etc.)
  def update_donor_category_tracking_data(donor_category, current_page_num, is_last_page, products_on_page, iterator)
    donor_category_update_params = {last_parsed_page_number: current_page_num}

    donor_category_update_params.merge!({products_per_page: products_on_page}) if iterator == 1

    donor_category_update_params.merge!({last_known_page_number: current_page_num,
                                         product_parsing_finished_at: Time.zone.now}) if is_last_page

    donor_category.update(donor_category_update_params)
  end


  # TODO implement removing dead products
  def parse_product(donor_product)
    # @general_logger.info("#{Time.zone.now} Start scrapping data of donor product(parser#parse_product): id: #{donor_product.id}; url: #{donor_product.url};")

    selector = @product_selector unless @product_selector.nil?

    product_nodes = {}
    product_data  = { name: nil, description: nil }

    page_html = get_page_html(donor_product.url)

    if page_html.nil?
      @general_logger.warn("#{Time.zone.now} get_page_html return nil (parser#parse_product): id: #{donor_product.id}; url: #{donor_product.url};")
      return false
    end

    # Name
    product_nodes[:name] = page_html.at_css(selector[:name])

    if product_nodes[:name].nil?
      @general_logger.warn("#{Time.zone.now} get_page_html NAME==nil (parser#parse_product): id: #{donor_product.id}; url: #{donor_product.url};")
      return false
    end

    product_data[:name] = get_name(product_nodes[:name]) + add_name(page_html)

    # Prices
    product_data.merge! get_product_prices(page_html, selector[:price])

    if product_data[:price].nil?
      @general_logger.warn("#{Time.zone.now} get_page_html PRICE==nil (parser#parse_product): id: #{donor_product.id}; url: #{donor_product.url};")
      return false
    end


    # TODO: decide, do we need it?
    # product_nodes[:image_url] = page_html.at_css(selector[:image])

    # Description
    product_nodes[:description] = page_html.css(selector[:description])
    product_data[:description] = product_nodes[:description].inner_html.strip unless product_nodes[:description].blank?

    # Brand
    if selector[:brand].present?
      product_data[:brand_id] = get_brand_id(page_html, selector[:brand])
    end

    # Product specifications
    if selector[:specification].present?
      product_nodes[:specification] = page_html.css(selector[:specification])
      parse_specifications(product_nodes[:specification], donor_product) if product_nodes[:specification].present? #&& !DRY_RUN
    end

    save_gallery(donor_product.id, page_html.css(selector[:images]), selector[:images_attr])

    ap product_data if DRY_RUN

    DonorProductUpdateWorker.perform_async(donor_product.id, product_data) unless DRY_RUN
  end

  ##
  # Get categories to parse: donor category with all it's descendants
  def donor_categories_to_parse(donor_category_id =nil)
    donor_categories = DonorCategory.where(donor_id: @donor.id)

    if donor_category_id.nil? # Parse only connected and active donor categories
      donor_categories.where(active: true).joins(:categories)
        .order("donor_categories.product_parsing_finished_at ASC").uniq
    else
      donor_categories.where(id: donor_category_id) # category & all it's children
    end
  end

  def check_infinite_loop?
    self.respond_to?(:is_infinite_loop?, true)
  end

  protected

  def paginate_substring(page_number)
    "?page=#{page_number}"
  end

  def init_agent
    Mechanize.new { |agent|
      agent.redirect_ok = false
      agent.user_agent_alias = 'Mac Safari'
      #adds proxy
      #agent.set_proxy('180.250.32.66', 80)
      # TODO - set better option
      agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    }
  end

  def update_donor_product(donor_product_id, params)
    params[:description] = params[:description].to_s if params[:description].present?
    DonorProductUpdateWorker.perform_async(donor_product_id, params)
  end

  # def save

  ##
  # Save donor product link in background.
  # @see #parse_categories_structure
  def save_donor_product_link(donor_category_id, donor_product_data)
    donor_product_data.merge!({donor_id: @donor.id})
    DonorProductCreateWorker.perform_async(donor_category_id, donor_product_data)
  end

  ##
  # Make full donor URL: protocol + donor domain.
  # Default case. For special case (for example: HTTPS or subdomain) just override this method in child class.
  # @see #get_link_path, #parse_category_page, #parse_products
  def donor_domain
    @donor.url
  end

  ##
  # Format text string for prettify name for category, product:
  # * get content from Nokogiri css node
  # * capitalizes all the words and replaces some characters in the string to create a nicer looking title
  # * add spaces around `/` if present
  # * remove all whitespace on both ends of the string, and changing whitespace groups into one space each
  def get_name(node)
    node.content.titleize.gsub('/', ' / ').squish unless node.nil? || node.content.nil?
  end

  ##
  # Format link path:
  # * remove donor domain
  # * remove all whitespace on both ends of the string, and changing whitespace groups into one space each
  # * if first character not `/` then add it
  def get_link_path(url)
    ((link_path = url.sub(@donor.url, '').squish)[0] == '/') ? link_path : ('/' + link_path)
  end

  ##
  # Parse general link tag and return name and path in hash.
  # @param remove_children - remove all children from node and leave direct content of <a> as name
  # Example:
  # 1. <a href="/test1"><span>Test1</span></a> `remove_children = false` will produce `Test1`
  # 2. <a href="/test2">Test2 <span>(20)</span></a> `remove_children = true` will produce `Test2`
  # @see #get_name, #get_link_path
  def get_link(node, remove_children = false)
    { name: get_name(remove_children ? node.children.remove.first : node), path: get_link_path(node[:href]) }
  end

  ##
  # Parse float number from Nokogiri node.
  # @see #get_product_prices
  # TODO: create method for converting String --> Float price like `Rp 360,000 - Rp 375,000`:
  # price.strip.split('-').first.gsub(/[^\d\.]+/, '').to_f
  def get_float(node)
    node.content.squish.gsub(/[^\d\.]+/, '').to_f if node.present? && node.content.present?
  end

  ##
  # Make GET or POST request +method+ to +url+ with +query+ parameters with error handling.
  # @raise Mechanize::Error if error while page requesting.
  # @raise Timeout::Error if page request timeout exceeded.
  # @raise Net::HTTP::Persistent::Error
  # @raise Exception if some unknown error.
  # @return {} | Nokogiri::HTML
  # Empty Hash result (in case of HTTP error) you can use by running upon it following useful methods:
  # {}.present? #=> false
  # {}.blank?   #=> true
  # {}.empty?   #=> true
  def get_page_html(url, method = :get, query = {})
    page_html = {}
    tryouts = 0

    begin
      tryouts += 1

      # Get page html
      page = (method == :post) ? @agent.post(url, query) : @agent.get(url)

    rescue Mechanize::Error => error
      # Currently, this exception will be thrown if Mechanize encounters response codes other than 200, 301, or 302:
      # Handle response codes: 404, 500, 503 etc
      display_http_error(code: error.response_code, url: url)
      @get_page_logger.warn("#{Time.zone.now} donor product GOT STATUS ERROR (parser#get_page_html): url: #{url}; errors: #{error.inspect}")

      if error.response_code[/404/]
        @get_page_logger.warn("#{Time.zone.now} donor product GOT 404 STATUS ERROR (parser#get_page_html): url: #{url}; errors: #{error.inspect}")
      else
        if tryouts < 3
          display_info("Retry request \e[33;1m#{tryouts}\e[0m time...")
          retry
        end
      end

    rescue Timeout::Error => error
      display_error("\e[34;1mTimeout expired\e[0m \e[31;1m#{error.message}\e[0m")
      @get_page_logger.warn("#{Time.zone.now} donor product GOT TIMEOUT STATUS ERROR (parser#get_page_html): url: #{url}; errors: #{error.inspect}")

    rescue Net::HTTP::Persistent::Error => error
      display_error("\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m")
      @get_page_logger.warn("#{Time.zone.now} donor product GOT Net::HTTP::Persistent::Error ERROR (parser#get_page_html): url: #{url}; errors: #{error.inspect}")
      return

    rescue Exception => error

      display_error("\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m")
      @get_page_logger.warn("#{Time.zone.now} donor product GOT EXCEPTION => e ERROR (parser#get_page_html): url: #{url}; errors: #{error.inspect}")

    else # Handle response codes: 200, 301, 302

      if page.code[/200/]
        @get_page_logger.warn("#{Time.zone.now} donor product STATUS 200-- (parser#get_page_html): url: #{url}; errors: #{error.inspect}")
        page_html = Nokogiri::HTML(page.body)

      elsif page.code[/30[12]/] # 301, 302 redirects
        display_http_error(code: page.code, url: url)

        display_info("Follow redirect --> \e[34;1m#{page.header['location']}\e[0m")
        @get_page_logger.warn("#{Time.zone.now} donor product FOLLOW REDIRECT 301 | 302 (parser#get_page_html): url: #{url}; code: #{page.code}")
        page_html = get_page_html(page.header['location'])

      else # Unexpected response code
        display_http_error(code: page.code, url: url)
        @get_page_logger.warn("#{Time.zone.now} donor product FOLLOW REDIRECT 301 | 302 (parser#get_page_html): url: #{url}; code: #{page.code}")
      end

    ensure
      # NOTE: `return` statement added here to fix incorrect behaviour when `begin..rescue..ensure..end` return
      # `TrueClass` instead of empty Hash `{}` if response code not 200 (any HTTP error occur).
      return page_html
    end
  end

  ##
  # Print HTTP error string: status code and URL. This is used by #get_page_html.
  def display_http_error(error)
    display_error("\e[33;1m#{error[:code]} #{Rack::Utils::HTTP_STATUS_CODES[error[:code].to_i]
                  }\e[0m for \e[34;1m#{error[:url]}\e[0m")
  end

  ##
  # Print string with error marker.
  def display_error(message)
    puts "\e[31;1m[ERROR]\e[0m #{message}"
  end

  ##
  # Print string with info marker.
  def display_info(info)
    puts "\e[34;1m[INFO]\e[0m #{info}"
  end

  ##
  # Print info string if dry run mode.
  def dry_run_notification
    display_info("\e[31;1mDry run!\e[0m") if DRY_RUN
  end

  ##
  # Print category name and path with indentation and create tree. This is used by #parse_category_tree.
  def display_category_structure(category_link, prefix = '', suffix = '')
    puts "#{prefix}-> `\e[33;1m#{category_link[:name]}\e[0m` => `\e[34;1m#{category_link[:path]}\e[0m`#{suffix}"
  end

  ##
  # Create donor category or update it's EN or TH name depending from the language.
  def save_category(category_link, parent_id = nil)
    # Try to find donor category
    category = DonorCategory.find_by_donor_id_and_path(@donor.id, category_link[:path])
    # category = DonorCategory.find_or_create_by(donor_id: @donor.id, path: params[:path])

    params     = { donor_id: @donor.id, parent_id: parent_id, path: category_link[:path] }
    name_param = { ('en' == @lang) ? :name_eng : :name => category_link[:name] }

    if category.nil? # If category not exists then create it
      category = DonorCategory.create(params.merge(name_param))
    else # if category exits then update only it's name
      category.update(name_param)
    end

    category
  end

  ##
  # Parse products inside category with all it's subcategories.
  def parse_categories_structure(donor_category_id = nil, selector = { product_link: '', next_page_link: '' })
    # dry_run_notification

    donor_categories = donor_categories_to_parse(donor_category_id)
    total_products_count = 0

    display_info "Total categories count: \e[34;1m#{donor_categories.count}\e[0m"

    donor_categories.find_each do |donor_category|
      category_products_count = 0
      page_number             = page_to_parse(donor_category)
      is_parse_next_page      = true
      category_page = { links: [], is_next_page: false, next_page_link: '' }

      while is_parse_next_page # Parse category page by page, until next page exists
        category_page = parse_category_page(donor_category, category_page[:next_page_link], page_number, selector)

        category_page[:links].each { |link| save_donor_product_link(donor_category.id, link) } unless DRY_RUN

        is_parse_next_page = category_page[:is_next_page]
        category_products_count += category_page[:links].count
        page_number += 1
      end

      category_name = "#{donor_category.name_eng.blank? ? donor_category.name : donor_category.name_eng} (id: #{donor_category.id})"

      if category_products_count > 0
        display_info "Category\e[0m \e[33;1m#{
                     category_name}\e[0m \e[32;1mparsed successfully!\e[0m Products count: \e[34;1m#{
                     category_products_count}\e[0m"

        total_products_count += category_products_count
      else
        display_error "Category\e[0m \e[33;1m#{
                      category_name}\e[0m \e[31;1mparsed unsuccessfully!\e[0m Products count: \e[34;1m#{
                      category_products_count}\e[0m"
      end

      # category.update(product_list_parsed_at: Time.zone.now) unless DRY_RUN # Update category product list parse date
    end
    display_info "Total products count: \e[34;1m#{total_products_count}\e[0m"
  end

  def page_to_parse(donor_category)
    # if previous scrapper run hasn't complete all pages - start from last scrapped one
    # else start from first page
    page = 1
    if !donor_category.all_pages_scrapped? && donor_category.last_parsed_page_number.present?
      page = donor_category.last_parsed_page_number
    end
    page
  end

  ##
  # Parse category page and get all products URLs.
  def parse_category_page(category, page_link, page_number, selector = { product_link: '', next_page_link: '' })
    category_page = { links: [], is_next_page: false, next_page_link: '' }

    page_link = "#{@donor.url}#{page_link.blank? ? category.path : page_link}"
    category_name = "#{category.name_eng.blank? ? category.name : category.name_eng} (id: #{category.id})"

    display_info "Category: \e[33;1m#{category_name}\e[0m, \e[34;1m#{
                 page_link}\e[0m, page: \e[34;1m#{page_number}\e[0m\n#{'-' * 80}\e[0m"

    page_html = get_page_html page_link
    return category_page if page_html.blank?

    links_html = page_html.css(selector[:product_link])

    next_page_link_node = page_html.css(selector[:next_page_link]).last
    category_page[:next_page_link] = get_link_path(next_page_link_node[:href]) unless next_page_link_node.blank?
    category_page[:is_next_page]   = !category_page[:next_page_link].blank?#include?('javascript:void(0)') # .empty?

    if links_html.blank?
      display_error "Products links not found #{category_page[:is_next_page] ?
                      'Go to next page' :
                      'Next page not found'}"
    else
      links_html.each { |link| category_page[:links] << get_link_path(link[:href]) unless link[:href].blank? }

      display_info "\e[32;1mProducts links ok. #{'Go to next page' if category_page[:is_next_page]}\e[0m"
      ap ["Products count = #{category_page[:links].count}", category_page]
    end

    category_page
  end

  def get_brand_id(doc, selector)
  end

  ##
  # Parse product card specifications.
  def parse_specifications(table_rows_html, donor_product)
    table_rows_html.each do |row|
      spec_node, val_node = row.css('td')

      spec = get_name spec_node #spec_node.at_css('span')
      val  = get_name val_node  #val_node.at_css('span')

      unless spec.blank? || val.blank?
        # Search for specification name
        spec_obj = Specification.find_or_create_by(name: spec)
        # Search for specification value
        spec_value_obj = spec_obj.specification_values.find_or_create_by(name: val)
        # Create link to donor_product
        donor_product.donor_products_specification_values.create(specification_value_id: spec_value_obj.id)
        # ap [spec_obj, spec_value_obj]
      end
    end
  end

  ##
  # Parse product prices from page html.
  def get_product_prices(page_html, selector = { price: nil, old_price: nil }) #, saving: ''
    product_data  = { price: nil, old_price: nil } #, saving: nil

    selector.each { |key, value| product_data[key] = get_float(page_html.css(value).last) }

    product_data
  end

  ##
  # Parse product card and update product price.
  # def update_prices(donor_product, selector)
  #   dry_run_notification
  #
  #   @donor_product = donor_product
  #
  #   display_info "Product: id = \e[34;1m#{@donor_product.id}\e[0m, path = \e[34;1m#{
  #                @donor_product.path}\e[0m, created_at = \e[34;1m#{@donor_product.created_at}\e[0m\n#{'-' * 80}"
  #
  #   page_html = get_page_html(@donor_product.url)
  #
  #   product_prices = get_product_prices(page_html, selector)
  #   ap product_prices if DRY_RUN
  #
  #   if product_prices[:price].present? || product_prices[:old_price].present?
  #     update_donor_product(@donor_product.id, product_prices) unless DRY_RUN
  #   else
  #     display_error 'Empty price!'
  #   end
  # end

  #for sites with duplicate products names
  def add_name(page_html)
    ''
  end

  ##
  # Initialize Capybara engine for sites with AJAX.
  # @param [Boolean] debug   Turn on/off debug messages.
  def initialize_capybara(debug = false, driver = :webkit)
    Capybara::Webkit.configure do |config|
      config.debug = debug
      config.allow_unknown_urls
      config.ignore_ssl_errors
      #adds proxy
=begin
      config.use_proxy(
        host: '180.250.32.66',
        port: 80,
        user: nil,
        pass: nil
      )
=end
      # TODO test this solution
      # config.skip_image_loading
    end

    Capybara.default_max_wait_time = 15 # 15..30s
    Capybara.default_driver = driver

    # for local test
    # Capybara.default_driver = :selenium
    @browser = Capybara.current_session
  end

  def run_headless
    headless = Headless.new
    headless.start

    yield

    headless.destroy
  end

  ##
  # Load page using Capybara for sites with AJAX.
  # @param [String] url   URL of page to load.
  def load_page(url)
    retries_count = 0
    # For use URLs with TH symbols.
    url = URI.encode(url)
    begin
      retries_count += 1
      @browser.visit url
    rescue Exception => error
      display_error "\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m"
      Rollbar.error(error, 'Parser#load_page', {url: url})

      if retries_count < 3
        display_error "##{__method__} failed for \e[34;1m#{url}\e[0m"
        display_info "Retry request \e[33;1m#{retries_count}\e[0m time..."
        retry
      else
        display_error "All attempts are exhausted! Failed to load \e[34;1m#{url}\e[0m"
        @browser = nil
      end
    end
  end

  def get_expected_product_number(donor_category, selector)
    url = donor_category.url
    doc = visit_page(url)
    return if doc.blank? || doc.at_css(selector).nil?

    expected_product_number = doc.at_css(selector).text.gsub(/\D/, '').to_i
    puts "category url             #{url}"
		puts "expected products count: #{expected_product_number}\n"

    donor_category.update(expected_number_of_products: expected_product_number)
  end

  def visit_page(url)
    get_page_html(url)
  end

  def get_page_url(donor_category_url, substring)
    "#{donor_category_url}#{substring}"
  end
end
