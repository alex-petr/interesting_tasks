##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.1577shop.com domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class Shop1577Parser < Parser

  PRICE_CSS_SELECTOR = { price: 'div.iSpecialPrice', old_price: 'div.iNormalPrice' }

  def initialize(*args)
    @product_selector = {
      price: PRICE_CSS_SELECTOR,
      name: '.product-name h1',
      images: '.product-image-gallery img',
      images_attr: :src,
      description: '.tabcontents'
    }

    @products_iterator_selector = 'li.iItemProductList'
    super
  end

  # Parse donor category tree with 2 levels nesting.
  def parse_category_tree
    page_html = get_page_html @donor.url
    return false if page_html.class.to_s == 'Hash'

    page_html.css('ul.iMenuList li a').each do |node|
      name = get_name(node)
      path = node[:href].gsub(@donor.url, '')
      next if path == 'http://www.1577shop.com/'
      save_category({name: name, path: path})
    end
  end

  def parse_donor_product_block(donor_product_node)
    name_node = donor_product_node.at_css('div.iProductNameList a')
    path = get_path(name_node)
    name = get_name(name_node)

    price = get_float(donor_product_node.at_css('div.iPriceSpecialPrice'))
    old_price = get_float(donor_product_node.at_css('div.iPriceNormalPrice'))

    {path: path, price: price, name: name, old_price: old_price}
  end

  def get_path(node)
    return if node.nil?

    node[:href].gsub(@donor.url, '') if node[:href].present?
  end

  def paginate_substring(page_number)
    "?p=#{page_number}"
  end

  def last_page?(doc, page_num)
    doc.at_css('a.next.i-next').nil?
  end
end
