##
# = Scraper class.
# Perform categories, product links, product info scraping of http://www.jib.co.th domain.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class JibParser < Parser
  PRICE_CSS_SELECTOR = { price: '#product_wrap .pro_detail .pro_price span',
                         old_price: '#product_wrap .pro_detail .pro_price .price_discount' }

  def initialize(*args)
    @product_selector = {
      price: PRICE_CSS_SELECTOR,
      name: '#product_wrap h1',
      images: '#product_wrap .product_gallery img',
      images_attr: :src,
      description: '#product_wrap #home',
      specifications: '#product_wrap #profile table tr'
    }

    @products_iterator_selector = 'div.product_sale > div'
    super
  end

  ##
  # Parse donor category tree with 2 levels nesting.
  def parse_category_tree
    dry_run_notification
    sub_menu_url = "#{donor_domain}/web/index.php/home/data_sub_menu"
    page_html = get_page_html "#{donor_domain}/web/"
    page_html.css('#menu_ul li').each do |parent_category|
      parent_category_id = parent_category[:source3]
      next if parent_category_id.blank?

      # Get sub menu html by category id
      sub_menu_page_html = get_page_html(sub_menu_url, :post, { cat_id: parent_category_id })

      next if sub_menu_page_html.blank?

      parent_category_link = get_link sub_menu_page_html.at_css('a')

      # Parent category name en/th language versions separated by "/"
      parent_category_link[:name] = parent_category_link[:name].split(' / ')[('en' == @lang) ? 0 : 1]
      category_parent = save_category(parent_category_link) unless DRY_RUN
      display_category_structure(parent_category_link, "#{'-' * 80}\n")

      sub_menu_page_html.css('.inner > ul > li').each do |subcategory_first_level_node|
        subcategory_first_level_link_node = subcategory_first_level_node.at_css('.a_header')
        subcategory_first_level_link = get_link(subcategory_first_level_link_node)
        # Name convert notes:
        # 1. Get raw link html with inner_html() in order to get en/th language versions separated by "<br>"
        # 2. Method content() convert html entities to characters: &Amp; --> &, &#3650;&#3607; --> โท
        # 3. Converting methods order: squish() must be the last operation, otherwise spaces left
        subcategory_first_level_link[:name] = get_name(
          Nokogiri::HTML.fragment subcategory_first_level_link_node.inner_html.split('<br>')[('en' == @lang) ? 0 : 1]
        )
        subcategory_first_level = save_category(subcategory_first_level_link, category_parent.id) unless DRY_RUN
        display_category_structure(subcategory_first_level_link, ' ' * 2)

        subcategory_first_level_node.css('.sub_menu a').each do |subcategory_second_level_node|
          subcategory_second_level_link = get_link(subcategory_second_level_node)
          save_category(subcategory_second_level_link, subcategory_first_level.id) unless DRY_RUN
          display_category_structure(subcategory_second_level_link, ' ' * 4)
        end
      end
    end if page_html
  end

  def parse_donor_product_block(donor_product_node)
    path = '/web/' + donor_product_node.at_css('div.product_des > div > a')[:href]
    name = get_name(donor_product_node.at_css('strong > a'))

    price = get_float(donor_product_node.at_css('font.price'))
    old_price = get_float(donor_product_node.at_css('span[style="text-decoration:line-through;"]'))

    {path: path, price: price, name: name, old_price: old_price}
  end

  def paginate_substring(page_number)
    page_number -= 1
    page_number * 100
  end

  def last_page?(doc, page_num)
    doc.at_css('ul.tsc_pagination.tsc_paginationA.tsc_paginationA01 > li.current + li').nil?
  end

  def get_page_url(donor_category_url, substring)
    donor_category_url.slice!(/.{2}$/)
    "#{donor_category_url}#{substring}"
  end

  def update_image_url(img_url)
    @donor.url + img_url
  end
end
