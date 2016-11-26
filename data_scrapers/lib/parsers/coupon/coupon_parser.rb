require 'open-uri'
class CouponParser < Parser
  def initialize
    @coupon_donor = CouponDonor.find_by(parser_class: self.class.to_s)
    @agent = Mechanize.new { |agent|
      agent.redirect_ok = false
      agent.user_agent_alias = 'Mac Safari'
    }
  end

  def get_brand(category)
    Brand.where(name: category).first_or_create
  end

  def get_donor(donor_name)
    # Donor.where('domain ILIKE ?', "%#{store}%").first
    donor_name = donor_name.parameterize.underscore.to_sym if donor_name.is_a? String
    Donor.find_by_domain(CouponDonor::DONORS[donor_name])
  end

  ##
  # Process coupon url: get rid of redirects, replace coupon url by brand/donor destination url.
  def process_url(url)
    final_url, tryouts = '', 0
    begin
      tryouts += 1
      page = @agent.get(url) # Get page html
    rescue Mechanize::Error => error
      # Currently, this exception will be thrown if Mechanize encounters response codes other than 200, 301, or 302.
      display_http_error(code: error.response_code, url: url)
      if !error.response_code[/404/] && tryouts < 3
        display_info("Retry request \e[33;1m#{tryouts}\e[0m time...")
        retry
      end
    rescue Timeout::Error => error
      display_error("\e[34;1mTimeout expired\e[0m \e[31;1m#{error.message}\e[0m")
    rescue Exception => error
      display_error("\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m")
    else # Handle response codes: 200, 301, 302
      if page.code[/200/] # Finally get rid of all redirects and can return current url.
        final_url = page.uri.to_s
      elsif page.code[/30[12]/] # 301, 302 redirects
        display_http_error(code: page.code, url: url)
        display_info("Follow redirect --> \e[34;1m#{page.header['location']}\e[0m")
        return process_url(page.header['location']) # Follow redirect
      else # Unexpected response code
        display_http_error(code: page.code, url: url)
      end
    ensure
      final_url
    end
  end
end
