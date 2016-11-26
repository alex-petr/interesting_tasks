##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.coszi.com domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class CosziParser < Parser

  PRICE_CSS_SELECTOR = { price: '.product-shop .price', old_price: '.product-shop .old-price .price' }

  ##
  # Parse donor category tree with 1 level nesting.
  def parse_category_tree
    dry_run_notification

    page_html = get_page_html donor_domain

    if page_html
      # Get menu JS from <script> tag
      menu_js_string = ''
      page_html.css('script').each do |script_string|
        menu_js_string = script_string.content if script_string.content.include? 'custommenu'
      end

      # Get menus html fragments from Base64
      unless menu_js_string.blank?
        menu_js_base64_sequence = menu_js_string.split('Base64.decode(\'').drop(1)

        unless menu_js_base64_sequence[0].blank?
          # Parent category converting
          parent_category_html = base64_to_html_fragment menu_js_base64_sequence[0]

          # Subcategories converting
          unless menu_js_base64_sequence[1].blank?
            subcategories_html = base64_to_html_fragment menu_js_base64_sequence[1]
            subcategories_html = subcategories_html.css('.wp-custom-menu-popup')
          end

          # Parent category parsing
          parent_category_html.css('.menu').each_with_index do |parent_category, index|
            parent_category_link = get_category_link(parent_category.at_css('a'), :rel)
            category_parent = save_category(parent_category_link) unless DRY_RUN
            display_category_structure(parent_category_link, "#{'-' * 80}\n")

            # Subcategories parsing
            unless subcategories_html[index].blank?
              subcategories_html[index].at_css('.itemMenu.level1 .itemMenu.level2').css('.itemMenuName.level2')
                .each do |subcategory_node|
                  subcategory_link = get_category_link(subcategory_node, :href)

                  save_category(subcategory_link, category_parent.id) unless DRY_RUN
                  display_category_structure(subcategory_link, ' ' * 2)
              end
            end
          end
        end
      end
    end
  end

  ##
  # Parse products inside category with all it's subcategories.
  def parse_categories_structure(category_id = nil)
    super category_id, { product_link: '.product-name a', next_page_link: '.next' }
  end

  ##
  # Parse product cards from specified category.
  def parse_products(category_id = nil)
    selector = {
      price: PRICE_CSS_SELECTOR,
      name: 'h1',
      image: 'a#cloudZoom',
      image_attr: :href,
      images: '.more-views a',
      images_attr: :href,
      description: '.product-specs',
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
  # CosziParser-specific method. Parse category link tag and return hash with name & path.
  def get_category_link(node, url_attribute)
    { name: get_name(node.at_css('span')), path: get_link_path(node[url_attribute]) }
  end

  ##
  # CosziParser-specific method. Convert Base64 menu sequence to `Nokogiri::HTML.fragment` for further html parsing.
  def base64_to_html_fragment(base64_sequence)
    menu_string = Base64.decode64(base64_sequence.split('\')')[0])
    menu_string = menu_string.encode('ASCII-8BIT', invalid: :replace, replace: '').force_encoding('UTF-8')
    Nokogiri::HTML.fragment menu_string
  end

end
