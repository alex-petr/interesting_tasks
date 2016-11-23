# Generate sitemaps. Learn more: https://github.com/kjvarga/sitemap_generator

# Choose basic settings according to environment.
if Rails.env.production?
  domain        = "https://#{Rails.application.secrets.HOST}"
  is_compressed = true
  extension     = '.xml.gz'
else # This section for debug purposes.
  domain        = 'http://localhost:3000'
  is_compressed = false
  extension     = '.xml'
end

# Folder, containing created sitemaps.
SITEMAPS_PATH = 'sitemaps/'

# Sitemap indexes list. Note: order is very important, because it's used in `SitemapGenerator::Sitemap.create`.
INDEXES = %w(coupons brands categories category_brands products)

# Default non-main sitemap options.
DEFAULT_OPTIONS = { default_host: domain, sitemaps_path: SITEMAPS_PATH, compress: is_compressed }

# Create main sitemap index file: `sitemap.xml`.
SitemapGenerator::Sitemap.create(default_host: domain, include_root: false, compress: false, filename: 'sitemap') do
  INDEXES.each do |index_name|
    add_to_index "#{SITEMAPS_PATH}#{index_name}#{extension}",
                 { lastmod: Time.zone.now, changefreq: 'daily', priority: 0.8 }
  end
end

# Create `Coupons` sitemap index file and sitemap files.
SitemapGenerator::Sitemap.create(DEFAULT_OPTIONS.merge filename: INDEXES[0]) do
  Coupon.where(approved: true).includes(:brand).find_each do |coupon|
    add coupon_brand_path(brand_url: coupon.brand.path, id: coupon.id), lastmod: coupon.updated_at, changefreq: 'daily', priority: 0.8
  end
end

# Create `Brands` sitemap index file and sitemap files.
SitemapGenerator::Sitemap.create(DEFAULT_OPTIONS.merge filename: INDEXES[1]) do
  Brand.find_each do |brand|
    add brand_path(brand_url: brand.path), lastmod: brand.updated_at, changefreq: 'daily', priority: 0.8
  end
end

# Create `Categories` sitemap index file and sitemap files.
SitemapGenerator::Sitemap.create(DEFAULT_OPTIONS.merge filename: INDEXES[2]) do
  Category.find_each do |category|
    add category_path(category_url: category.path), lastmod: category.updated_at, changefreq: 'daily', priority: 0.8
  end
end

# Create `Brands` in `Categories` (`:category_url/:brand_url`) sitemap index file and sitemap files.
SitemapGenerator::Sitemap.create(DEFAULT_OPTIONS.merge filename: INDEXES[3]) do
  Category.find_each do |category|
    brands_urls = Brand
                    .joins(:products => :categories)
                    .where('categories.id = ?', category.id)
                    .group('brands.id')
                    .order('brands.name').pluck(:path)

    brands_urls.each do |brand_url|
      add category_brand_path(category_url: category.path, brand_url: brand_url), lastmod: category.updated_at,
          changefreq: 'daily', priority: 0.8
    end
  end
end

# Create `Products` sitemap index file and sitemap files.
SitemapGenerator::Sitemap.create(DEFAULT_OPTIONS.merge filename: INDEXES[4]) do
  Product.find_each do |product|
    if product.url.present?
      add product_path(id: product.url, format: 'html'), lastmod: product.updated_at, changefreq: 'daily', priority: 0.8
    end
  end
end

# Ping search engines.
if is_compressed
  # Ping for main sitemap index file: `sitemap.xml`.
  SitemapGenerator::Sitemap.ping_search_engines("#{domain}/sitemap.xml")
  # Ping for sitemap index files.
  INDEXES.each do |sitemap_name|
    SitemapGenerator::Sitemap.ping_search_engines("#{domain}/#{SITEMAPS_PATH}#{sitemap_name}#{extension}")
  end
end
