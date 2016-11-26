##
# = Scraper class.
# Perform banners scraping from dropdown menus for http://lazada.co.th and http://lazada.co.id domains.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class LazadaBannerParser < BannerParser
  ##
  # Initialize Mechanize agent and get Lazada TH/ID donor.
  def initialize
    super
    @donor  = Donor.find_by parser_class: (is_host_indo? ? LazadaIdParser : LazadaParser)
    # Initialize logger with log format: SeverityID, [DateTime #pid] SeverityLabel -- ProgName: message
    @logger = ::Logger.new("#{Rails.root}/log/scrappers/lazada_banner_parser.log")
  end

  ##
  # Main parsing algorithm.
  def run
    parse_banners
    check_categories_connections
    save_banners
    finalize
  end

  private

  ##
  # Check if current host Indonesian.
  def is_host_indo?
    'shopsmart.co.id' == Rails.application.secrets.HOST
  end

  ##
  # Parsing banners info:
  # @banners = [ { :category_name => "อิเล็กทรอนิกส์",
  #                :banners => [ {
  #                  :url   => "http://www.lazada.co.th/shop-computers-laptops/",
  #                  :image => "http://th-live.slatic.net/cms/tracked/48/7/4/48740/48740_original.jpg"
  #                }, ... ] }, ... ]
  def parse_banners
    page_html = get_page_html @donor.url
    abort "Failed to get page html for #{@donor.url}" if page_html.blank?

    dropdown_menus_html = page_html.css 'div.c-second-menu'

    page_html.css('span.c-main-navigation__item').each_with_index do |menu_item, index|
      category_with_banners = { category_name: get_name(menu_item), banners: [] }

      dropdown_menus_html[index].css('a.c-banner').each do |banner_html|
        category_with_banners[:banners] << {
            url: "#{@donor.url}#{get_link_path(banner_html[:href])}",
            image: YAML.load(banner_html.at_css('span.c-img-lazy')['data-js-component-params'])['src']
          }
      end

      @banners << category_with_banners
    end
  end

  ##
  # Create/update #Banner and connect to multiple #Category.
  def save_banners
    @banners.each do |category_with_banners|
      banner_donor_category = @donor.donor_categories.find_by_name category_with_banners[:category_name]

      next if banner_donor_category.nil? || banner_donor_category.categories.empty?

      banner_category_ids = banner_donor_category.categories.pluck(:id)

      category_with_banners[:banners].each_with_index do |banner, index|
        banner_name = "#{banner_donor_category.name.titleize.squish} ##{index + 1}"
        save_banner({ name: banner_name, url: banner[:url], display: true }, banner_category_ids, banner[:image])
      end
    end
  end

  def check_categories_connections
    # If donor has no parsed categories then have to run `@donor.parse_category_tree`.
    abort "No parsed donor categories for donor: #{@donor.ai}" if @donor.donor_categories.blank?

    connected_categories_count = connected_root_categories
    total_root_categories      = @donor.donor_categories.roots.count
    @logger.info "Count of connected root categories: #{connected_categories_count} / #{total_root_categories}"

    # If none of the categories connected.
    if connected_categories_count.zero?
      abort "No categories connected to donor categories for donor: #{@donor.ai}"
    else # If some of the categories not connected.
      @logger.warn 'Some of the categories not connected!' if connected_categories_count < total_root_categories
    end
  end

  ##
  # Create #Banner with `name`, `url`, `display`, but without `image` attachment or update `image`.
  def save_banner(params = {}, banner_category_ids, image_url)

    puts "Try to create banner with params: #{
      {params: params, banner_category_ids: banner_category_ids, image_url: image_url}.ai}"

    @logger.info "Try to create banner with params: #{
      {params: params, banner_category_ids: banner_category_ids, image_url: image_url}.ai}"

    remove_old_banner(params, image_url)

    if (existed_banner = Banner.find_by(params))
      if existed_banner.image_file_name != File.basename(image_url)
        puts 'Donor updated image, updating banner...'
        @logger.info 'Donor updated image, updating banner...'
        existed_banner.category_ids = banner_category_ids
        save_banner_image(existed_banner, image_url)
      else
        puts 'Banner exist and donor image not changed!'
        @logger.warn 'Banner exist and donor image not changed!'
      end
      @logger.ap existed_banner
    else
      puts 'Banner does not exist, creating...'
      @logger.info 'Banner does not exist, creating...'
      banner = Banner.new(params)
      if banner.save
        banner.category_ids = banner_category_ids
        save_banner_image(banner, image_url)
        puts "Banner `#{banner[:name]}` created successfully!"
        @logger.info "Banner `#{banner[:name]}` created successfully!"
      else
        puts "There is error(s) during creating banner: #{banner.errors.ai}"
        @logger.error "There is error(s) during creating banner: #{banner.errors.ai}"
      end
    end
  end

  ##
  # Download image attachment by URL and save to #Banner.image.
  def save_banner_image(banner, image_url)
    begin
      banner.image = uri_encode image_url
      banner.save
      @logger.info "Banner `#{banner[:name]}` image saved!"
    rescue Exception => error
      # TODO: Add Rollbar informer.
      @logger.error("#{self.class}##{__method__}") { "#{error.class}<#{error.class.superclass.name} #{error.message}" }
    end
  end

  ##
  # Count #Categories connected to #Donor.donor_categories.
  def connected_root_categories
    count = 0
    @donor.donor_categories.roots.each_with_index do |donor_category, index|
      connected_categories_count = donor_category.categories.count
      connected = ''
      donor_category.categories.each do |category|
        connected << "[id=#{category.id} #{category.name_eng}/#{category.name}]"
      end
      @logger.info "##{index + 1} id=#{donor_category.id} #{donor_category.name_eng}/#{donor_category.name} "\
        "connected=#{connected_categories_count} #{connected}"
      count += 1 if connected_categories_count > 0
    end
    count
  end

  ##
  # Fatal program termination. Message is written to log before it closed and program terminated.
  # @param [String] message to be logged.
  def abort(message)
    @logger.fatal("#{self.class}##{caller_locations(1, 1)[0].label}") { message }
    finalize
    Kernel.abort
  end

  ##
  # Add line break before closing logger to separate parser working sessions.
  def finalize
    @logger << "\n"
    @logger.close
  end

  def remove_old_banner(new_banner_params, image_url)
    old_banner = Banner.find_by(name: new_banner_params[:name])
    return if old_banner.nil?

    return if old_banner[:url] == new_banner_params[:url] && image_url.include?(old_banner[:image_file_name])

    old_banner.destroy
  end
end
