##
# = Scraper class.
# Perform subdomains list, categories, product links, product info scraping of https://www.lnwshop.com/shop/all domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class LnwShopParser < Parser
  PRICE_CSS_SELECTOR = { price: '.productLayout .priceTR .bodyTD span',
                         old_price: '.productLayout .oldpriceTR .bodyTD .price_old' }

  # This is used by #parse_subdomain_categories and #parse_subdomains.
  SUBDOMAINS_LIST_URI     = 'https://www.lnwshop.com/shop/all'

  # This is used by #backup_subdomains and #parse_subdomains.
  SUBDOMAINS_FILE_CURRENT = 'tmp/lnwshop_subdomains.txt'
  SUBDOMAINS_FILE_OLD     = 'tmp/lnwshop_subdomains.old.txt'

  ##
  # Initializer for class: first run parent, then replace donor with founded by domain one.
  def initialize(lang = 'th', domain = nil)
    super lang
    @donor = Donor.find_by_domain(domain) unless domain.nil?
    ap @donor
  end

  ##
  # Parse subdomain categories list.
  def parse_subdomain_categories
    dry_run_notification

    page_html = get_page_html SUBDOMAINS_LIST_URI

    ids = []

    if page_html
      page_html.css('#form_search_shop option').drop(1).each do |category|
        display_info "#{category[:value]} --> #{category.content}"

        ids << {id: category[:value], name: category.content}
      end
    end

    ids
  end

  ##
  # Keep subdomains list actual: perform backup, remove old, add new domains.
  def update_subdomains
    backup_subdomains
    parse_subdomains
  end

  ##
  # Import subdomains from text file to DB.
  # * open non-zero size +SUBDOMAINS_FILE_CURRENT+ for reading
  # * validate uri and get host from full URL: `http://www.i-lovedress.com/` --> `www.i-lovedress.com`
  # * save to donors table
  def import_subdomains_to_donors
    dry_run_notification

    display_info "`parser_class`: \e[34;1m#{self.class.to_s}\e[0m"

    if File.size?(SUBDOMAINS_FILE_CURRENT)
      File.open(SUBDOMAINS_FILE_CURRENT, 'r') do |file|
        while (subdomain = file.gets)
          host = URI.parse(subdomain.chomp).host

          unless host.blank?
            display_info "`domain`: \e[34;1m#{host}\e[0m"
            unless DRY_RUN
              Donor.
                create_with(market: true, logo: process_donor_logo(subdomain)).
                find_or_create_by(domain: host, parser_class: self.class.to_s)
            end
          end
        end
      end
    end
  end

  ##
  # Process and save donor logo.
  def add_subdomain_logo
    @donor.logo = process_donor_logo @donor.url
    @donor.save
  end

  ##
  # Parse donor category tree with 2 levels nesting.
  def parse_category_tree
    dry_run_notification

    page_html = get_page_html @donor.url

    if page_html
      main_category_last = page_html.css('.content > .main-cat').last
      return false if main_category_last.nil?
      main_category_last.css('> .cat-item > .middle').each do |parent_category|
        parent_category_link = get_category_link(parent_category.at_css('a'))

        next if parent_category_link[:name].empty? && parent_category_link[:path].empty?

        category_parent = save_category(parent_category_link) unless DRY_RUN
        display_category_structure(parent_category_link, "#{'-' * 80}\n")

        if parent_category
          parent_category.css('.main-cat > .cat-item > .middle').each do |subcategory_first_level_node|
            subcategory_first_level_link = get_category_link(subcategory_first_level_node.at_css('a'))

            subcategory_first_level = save_category(subcategory_first_level_link, category_parent.id) unless DRY_RUN
            display_category_structure(subcategory_first_level_link, ' ' * 2)

            subcategory_first_level_node.css('.main-cat > .cat-item > .middle').each do |subcategory_second_level_node|
              subcategory_second_level_link = get_category_link(subcategory_second_level_node.at_css('a'))

              save_category(subcategory_second_level_link, subcategory_first_level.id) unless DRY_RUN
              display_category_structure(subcategory_second_level_link, ' ' * 4)
            end
          end
        end
      end
    end
  end

  ##
  # Parse products inside category with all it's subcategories.
  def parse_categories_structure(category_id = nil)
    super category_id, { product_link:   '.productsArea .productArea .productDetail a',
                         next_page_link: '.productsArea .tsk-pageview .next a' }
  end

  ##
  # Parse product cards from specified category.
  def parse_products(category_id = nil)
    selector = {
      price: PRICE_CSS_SELECTOR,
      name: '.productHeaderBlock h1',
      images: '.productLayout .slideShow img',
      description: '.product_tab #detail'
    }
    super category_id, selector
  end

  ##
  # Parse product card and get product price
  def update_prices(donor_product)
    super donor_product, PRICE_CSS_SELECTOR
  end

  private

  ##
  # Remove old backup and create new from last non-zero size subdomains list. This is used by #update_subdomains.
  def backup_subdomains
    if File.size?(SUBDOMAINS_FILE_CURRENT) && !DRY_RUN
      File.exist?(SUBDOMAINS_FILE_OLD) && File.delete(SUBDOMAINS_FILE_OLD)
      File.rename(SUBDOMAINS_FILE_CURRENT, SUBDOMAINS_FILE_OLD)
    end
  end

  ##
  # Parse full subdomains list in descending shop open date order. If optional +category+ present, parse shops from
  # that category. This is used by #update_subdomains.
  def parse_subdomains(category = nil)
    dry_run_notification

    category = "cat=#{category}&" unless category.nil?
    page_number = 1
    is_parse_next_page = true

    while is_parse_next_page
      subdomains = []

      page_html = get_page_html "#{SUBDOMAINS_LIST_URI}/?s=latest&#{category}p=#{page_number}"

      subdomains_html = page_html.css('#allshop_container a')

      unless subdomains_html.empty?
        subdomain = ''

        subdomains_html.each { |link| subdomains << subdomain unless (subdomain = link[:href].squish).blank? }

        File.open(SUBDOMAINS_FILE_CURRENT, 'a') { |file| file.write(subdomains.join("\n") + "\n") } unless DRY_RUN
      end

      display_info "Page: \e[34;1m#{page_number}\e[0m"

      ap subdomains

      is_parse_next_page = !page_html.at_css('.next_shop').nil?
      page_number += 1
    end
  end

  ##
  # Parse subdomain category link tag and return name and path in hash.
  def get_category_link(node)
    { name: get_name(node.at_css('.name')), path: get_link_path(node[:href]) }
  end

  ##
  # Parse donor logo from main page.
  def process_donor_logo(donor_url)
    logo_url = nil

    page_html = get_page_html donor_url
    if page_html
      logo_node = page_html.at_css('link[rel="image_src"]')
      logo_url  = URI.parse(logo_node[:href]) unless logo_node.nil?
    end

    logo_url
  end

end
