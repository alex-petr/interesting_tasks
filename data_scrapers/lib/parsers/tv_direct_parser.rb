##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.tvdirect.tv domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
# TODO add logging, example: ActiveSupport::Logger.new('log/rake/tv_direct_categories.log')
#
class TvDirectParser < Parser
  PRICE_CSS_SELECTOR = { old_price: '.short-description + .price-info span[id*=old-price]', price: 'div.short-description + div.price-info span[id*=product-price]' }

  def initialize(*args)
    @product_selector = {
      price: PRICE_CSS_SELECTOR,
      name: '.product-shop .product-name .h1',
      images: 'div#marginframe_gallery > a',
      images_attr: 'data-image',
      description: '.product-view .description .std',
    }

    @products_iterator_selector = 'li.item'
    super
  end

  # Parse categories structure
  def parse_category_tree
    doc = get_page_html "#{@donor.url}/?___store=#{@lang}"

    # Parent: http://www.tvdirect.tv/health
    doc.css('nav#nav li.level0.parent').each do |first_level|
      first_level_info = get_link(first_level.at_css('a.level0'))
      next if first_level_info[:name].empty? && first_level_info[:path].empty?

      first_level_category = save_category(first_level_info)

      puts "#{'=' * 80}\n-> `#{first_level_info[:name]}` => `#{first_level_info[:path]}`\n#{'-' * 80}"

      # First level subcategory: http://www.tvdirect.tv/health/food-supplement
      first_level.css('li.level1').each do |second_level|
        second_level_info = get_link(second_level.at_css('a.level1'))

        second_level_category = save_category(second_level_info, first_level_category.id)

        puts "  -> `#{second_level_info[:name]}` => `#{second_level_info[:path]}`"

        # Second level subcategory: http://www.tvdirect.tv/health/food-supplement/vitamins-minerals
        second_level.css('li.level2').each do |third_level|
          third_level_info = get_link(third_level.at_css('a.level2'))

          save_category(third_level_info, second_level_category.id)

          puts "    -> `#{third_level_info[:name]}` => `#{third_level_info[:path]}`"
        end
      end
    end
  end

  def parse_donor_product_block(donor_product_node)
    path = donor_product_node.at_css('h2.product-name > a')[:href].gsub("#{@donor.url}", '')
    name = get_name(donor_product_node.at_css('h2.product-name'))

    price = get_float(donor_product_node.at_css('span.regular-price, p.special-price, span.special-price'))
    old_price = get_float(donor_product_node.at_css('p.old-price'))

    {path: path, price: price, name: name, old_price: old_price}
  end

  def paginate_substring(page_number)
    "?limit=80&p=#{page_number}"
  end

  def last_page?(doc, page_num)
    doc.at_css('div.pages > ol > li > a.next.i-next').nil?
  end
end
