##
# = Scraper class.
# Perform categories, product links, product info scraping of http://weloveshopping.com domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class WeLoveShoppingParser < Parser
  PRICE_CSS_SELECTOR = { price: '.product-detail #product-price',
                         old_price: '.product-detail .price-compare' }

  MAIN_PAGE_REDIRECT_URL = '/'

  EXCLUDE_SELLERS = %w(siwancrystal cheekkastore gadgetworld sriva goodyx2 playtime the-skincare cheapgoods artbeautyshop)


  def initialize(*args)
    @product_selector = {
      price: PRICE_CSS_SELECTOR,
      name: 'h1.product-name',
      images: '#product-thumb-scroller ul li',
      images_attr: :'data-zoom-image',
      description: '.product-more-detail #howto-description',
    }

    @products_iterator_selector = 'ul.items-list-box > li'
    super
  end


  ##
  # Parse donor category tree with 2 levels nesting.
  def parse_category_tree
    dry_run_notification

    page_html = get_page_html "#{donor_domain}/sitemap"

    if page_html
      page_html.css('#category + div.box-overflow .box-sitemap-list .item').each do |parent_category|
        parent_category_link = get_category_link(parent_category.at_css('strong a'))

        next if parent_category_link[:name].empty? && parent_category_link[:path].empty?

        category_parent = save_category(parent_category_link) unless DRY_RUN
        display_category_structure(parent_category_link, "#{'-' * 80}\n")

        if parent_category
          parent_category.css('a:not(:first-child)').each do |subcategory_first_level_node|
            subcategory_first_level_link = get_category_link(subcategory_first_level_node)

            subcategory_first_level = save_category(subcategory_first_level_link, category_parent.id) unless DRY_RUN
            display_category_structure(subcategory_first_level_link, ' ' * 2)
          end
        end
      end
    end
  end

  def parse_donor_product_block(donor_product_node)
    path = donor_product_node.at_css('a')[:href].gsub("#{@donor.url}", '')
    name = get_name(donor_product_node.at_css('.item-name'))
    price_block_node = donor_product_node.at_css('.box-overflow')
    price_result = get_product_prices(price_block_node, {price: '.price', old_price: '.compare'})

    price = price_result[:price]
    old_price = price_result[:old_price]

    {path: path, price: price, name: name, old_price: old_price}
  end

  def paginate_substring(page_number)
    "?p=#{page_number}"
  end

  def last_page?(doc, page_num)
    doc.at_css('.pagination li.ctrl-page').nil? || !doc.at_css('.pagination li.ctrl-page.disabled i.fa-chevron-right').nil?
  end


  def parse_expected_product_number(donor_category)
    page_url = donor_category.url

    doc = get_page_html(page_url)

    return false if doc.nil?

    expected_products_selector = "span.num-items-title"

    expected_products_node = doc.at_css(expected_products_selector)
    unless expected_products_node.nil?
      expected_products = expected_products_node.text.gsub(/\D/, '').to_i
      donor_category.update(expected_number_of_products: expected_products)
    end
  end


  def redirect_donor_category_action(donor_category, new_url =nil)
    return false if new_url.nil?

    new_path = URI.parse(new_url).path

    if new_path == "#{donor_category.donor.url}" || new_path.blank?
      not_found_donor_category_action(donor_category)
    else
      super(donor_category, new_url)
    end
  end

  # Parse subdomain category link tag and return name and path in hash.
  def get_category_link(node)
    { name: get_name(node), path: "/#{get_link_path(node[:href])}" }
  end

  def get_link_path(url)
    url.sub(donor_domain, '').squish
  end

end
