##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.konvy.com domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class KonvyParser < Parser
  PRICE_CSS_SELECTOR = { price:     '.detail_box_right .price_bg_box strong',
                         old_price: '.detail_box_right .discount .left strong.grey' }

  def initialize(*args)
    @product_selector = {
      price: PRICE_CSS_SELECTOR,
      name: 'p.pro_name',
      image: '.detail_box_left img',
      image_attr: :src,
      images: '.detail_info_box .detail p img',
      images_attr: :src,
      # description: '.detail_info_box .detail',
      description: '.detail div.lh25',
      specification: '.blk.detail table tr',
      brand: "td:has(span:contains('Brand')) + td"
    }

    # to select blocks of products on category page
    @products_iterator_selector = 'div.sc_display_con > ul > li'
    super
  end

  ##
  # Parse donor category tree with 2 levels nesting.
  def parse_category_tree
    doc = get_page_html(@donor.url)
    return if doc.nil?

    #parse 1st level
    doc.css('div.new_nav_left_pos.cateSub').each do |first_level|
      first_level_category = save_category(get_category_info(first_level, '.a_class'))

      #parse 2st level
      first_level.css('dl dt').each do |second_level|
        save_category(get_category_info(second_level, '.c_class'), first_level_category.id)
      end
    end
  end


  def parse_donor_product_block(donor_product_node)
    # ap donor_product_node
    path = donor_product_node.at_css('p.promo_product_cate a')[:href].gsub("#{@donor.url}", '')
    name = get_name(donor_product_node.at_css('p.promo_product_cate a'))

    price = get_float(donor_product_node.at_css('div.sc_por_jg span.srog'))
    old_price_node = donor_product_node.at_css('div.sc_por_jg del')

    old_price = nil
    old_price = get_float(old_price_node) unless old_price_node.nil?

    # ap result = {path: path, price: price, name: name, old_price: old_price}
    {path: path, price: price, name: name, old_price: old_price}
  end

  private

  def paginate_substring(page_number)
    "&page=#{page_number}"
  end

  # TODO
  def last_page?(doc, page_num)
    doc.at_css('div.sc_display_con ul.paginator > li:last').text.to_i == page_num
  end

  ##
  # Switch language via cookie.
  # def set_language_cookie
  #   cookie = Mechanize::Cookie.new('f34c_lang2', ('en' == @lang) ? 'en_US' : 'th_TH')
  #   cookie.domain = @donor.domain
  #   cookie.path   = '/'
  #   @agent.cookie_jar.add cookie
  # end

  ##
  # Overridden Parser#get_page_html method for language setting.
  # def get_page_html(url)
  #   set_language_cookie
  #   super url
  # end

  def get_category_info(node, name_css)
    { name: node.at_css(name_css).text.squish,
      path: node.at_css('> a')[:href].gsub(@donor.url, '') }
  end
end
