##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.1577shop.com domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class Shop1577Parser < Parser

  PRICE_CSS_SELECTOR = { price: '.product-shop .price', old_price: '.product-shop .old-price .price' }

  ##
  # Parse donor category tree with 2 levels nesting.
  def parse_category_tree
    dry_run_notification

    parent_category_page_html = get_page_html donor_domain

    if parent_category_page_html
      parent_category_page_html.css('#verticalmenu a').each do |parent_category_html|

        parent_category_link = get_link(parent_category_html)

        next if parent_category_link[:name].empty? && parent_category_link[:path].empty?

        parent_category = save_category(parent_category_link) unless DRY_RUN
        display_category_structure(parent_category_link, "#{'-' * 80}\n")

        subcategory_first_level_page_html = get_page_html(donor_domain + parent_category_link[:path])
        if subcategory_first_level_page_html
          subcategory_first_level_page_html.css('#narrow-by-list2 a').each do |subcategory_first_level_html|
            subcategory_first_level_link = get_link(subcategory_first_level_html, true)

            subcategory_first_level = save_category(subcategory_first_level_link, parent_category.id) unless DRY_RUN
            display_category_structure(subcategory_first_level_link, ' ' * 2)

            subcategory_second_level_page_html = get_page_html(donor_domain + subcategory_first_level_link[:path])
            if subcategory_second_level_page_html
              subcategory_second_level_page_html.css('#narrow-by-list2 a').each do |subcategory_second_level_html|
                subcategory_second_level_link = get_link(subcategory_second_level_html, true)

                save_category(subcategory_second_level_link, subcategory_first_level.id) unless DRY_RUN
                display_category_structure(subcategory_second_level_link, ' ' * 4)
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
      name: '.product-name h1',
      image: '#image-main',
      images: '.product-image-gallery img',
      images_attr: :src,
      description: '.tabcontents'
    }
    super category_id, selector
  end

  ##
  # Parse product card and get product price
  def update_prices(donor_product)
    super donor_product, PRICE_CSS_SELECTOR
  end

end
