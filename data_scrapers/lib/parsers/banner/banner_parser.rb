##
# = Scraper class.
# Perform banners scraping for different domains.
#
# @author Alexander Petrov <petrov@wearepush.co>
#
class BannerParser < Parser
  def initialize
    super
    @banners = []
  end
end
