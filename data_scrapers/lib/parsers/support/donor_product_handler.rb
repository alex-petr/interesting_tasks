module ParserSupport
  module DonorProductHandler

    def check_donor_product_status(donor_product)
      puts "-------------"
      puts "Check path: #{donor_product.url}"

      url = donor_product.url

      begin
        response = @agent.get(url)
      rescue Exception => e
        puts "Page expired!"
        puts "url: #{url}"
        not_found_donor_product(donor_product)
      else
        if response.code[/404/]
          puts "Page expired!"
          puts "url: #{url}"
          not_found_donor_product(donor_product)
        elsif response.code[/30[12]/] # 301, 302 redirects
          puts "Page redirected! #{response.code}"
          puts "redirect url: #{response.header['location']}"
          not_found_donor_product(donor_product) if redirect_to_non_product_page?(response.header['location'])
        else
          puts "its ok! #{url}"
        end
      end
    end

    def get_donor_product_info(donor_product)

    end

    def not_found_donor_product(donor_product)
      donor_product.destroy #unless Parser::DRY_RUN
      puts "Donor product: #{donor_product.path} destroyed!"
    end


  end
end
