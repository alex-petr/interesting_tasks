##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.oshoppingtv.com domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class OshoppingParser < Parser
  PRICE_CSS_SELECTOR = { old_price: '#contentsWarp div.infoList table td.price1',
                         price:     '#contentsWarp div.infoList table td.price2' }

  ##
  # Parse donor category tree with 2 levels nesting.
  def parse_category_tree
    dry_run_notification

    page_html = get_page_html "#{@donor.url}/mall/index.htm"
    return display_error "\e[33;1m#{self.class}##{__method__}\e[0m failed to get page html" if page_html.blank?

    page_html.css('#headerWarp .cateAllList ul li').each do |menu_item|
      category_link_level_1 = get_link menu_item.at_css('dt a')
      category_level_1      = save_category(category_link_level_1) unless DRY_RUN
      display_category_structure category_link_level_1, "#{'-' * 80}\n"

      menu_item.css('dd a').each do |menu_sub_item|
        category_link_level_2 = get_link menu_sub_item
        save_category(category_link_level_2, category_level_1.id) unless DRY_RUN
        display_category_structure category_link_level_2, '  '
      end
    end
  end

  ##
  # Parse products inside category with all it's subcategories.
  # @param [Integer] category_id   Category ID to parse product links inside.
  def parse_categories_structure(category_id)
    dry_run_notification

    total_products_count = 0
    categories = donor_categories_to_parse(category_id)
    display_info "Total categories count: \e[34;1m#{categories.count}\e[0m"

    initialize_capybara do
      categories.find_each do |category|
        category_name = "#{category.name_eng.blank? ? category.name : category.name_eng} (id: #{category.id})"
        category_products_count = parse_category category.id, category_name, "#{@donor.url}#{category.path}"
        total_products_count += category_products_count
        category_post_processing_message (category_products_count > 0), category_name, category_products_count
        # category.update(product_list_parsed_at: Time.zone.now) unless DRY_RUN # Update category product list parse date
      end
    end
    display_info "Total products count: \e[34;1m#{total_products_count}\e[0m"
  end

  ##
  # Parse product cards from specified category.
  # @param [Integer] category_id   Category ID to parse products inside.
  def parse_products(category_id)
    selector = {
      price:       PRICE_CSS_SELECTOR,
      name:        'h2#titleItem  span:first-child',
      image:       '.proImgArea a.cloud-zoom',
      image_attr:  :href,
      images:      '.proImgArea a.cloud-zoom',
      images_attr: :href,
      description: '.detailProduct .tab1Contents'
    }
    super category_id, selector
  end

  ##
  # Parse product card and update product price.
  # @param [DonorProduct] donor_product   Donor product for updating price.
  def update_prices(donor_product)
    super donor_product, PRICE_CSS_SELECTOR
  end

  private

  ##
  # Parse category page by page and save all products URLs.
  # @param [Integer] category_id
  # @param [String] name
  # @param [String] url
  # @return [Integer] count of parsed products in category
  def parse_category(category_id, name, url)
    category_links_count = 0 # Total links in category.
    page_number          = 1
    is_parse_next_page   = true

    load_page url
    return 0 unless @browser

    while is_parse_next_page
      category_page_links = [] # Links on one category page.
      display_info "Category: \e[33;1m#{name}\e[0m, \e[34;1m#{url}\e[0m, page: \e[34;1m#{page_number}\e[0m"

      product_links_html = @browser.find('#showWindow .columnType').all 'ul li p.p_title a'

      # Saving founded links.
      if product_links_html.blank?
        display_error 'Products links not found.'
      else
        product_links_html.each do |product_link_node|
          unless product_link_node[:href].blank?
            category_page_links << product_link = get_link_path(product_link_node[:href])
            category_links_count += 1
            save_donor_product_link(category_id, product_link) unless DRY_RUN
          end
        end
        display_info "Products count: \e[34;1m#{category_page_links.count}\e[0m"
        ap category_page_links
      end

      # Check for next page existing and selecting it.
      if @browser.first('#paging1 span a.select')
        if (next_page_link = @browser.first('#paging1 span a.select + a')) # Next after selected exists?
          next_page_link.click # Click on it.
        else
          if (next_ten_pages_link = @browser.first('#paging1 a.next')) # Next 10 pages button exists?
            next_ten_pages_link.click # Click on it.
          else
            is_parse_next_page = false
          end
        end
      else
        if (first_page_link = @browser.first('#paging1 span a')) # First page link exists?
          first_page_link.click # Click on it.
        else
          is_parse_next_page = false
        end
      end

      page_number += 1
    end

    category_links_count
  end

  ##
  # Display message after category parsing.
  # @param [Bool] is_success
  # @param [String] name
  # @param [Integer] products_count
  def category_post_processing_message(is_success, name, products_count)
    message = "Category\e[0m \e[33;1m#{name}\e[0m \e[%{color};1mparsed %{result}!\e[0m Products count: \e[34;1m#{
              products_count}\e[0m\n#{'-' * 80}"
    if is_success
      display_info message.sub('%{color}', '32').sub('%{result}', 'successfully')
    else
      display_error message.sub('%{color}', '31').sub('%{result}', 'unsuccessfully')
    end
  end

end
