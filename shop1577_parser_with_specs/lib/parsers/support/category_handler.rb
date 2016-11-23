module ParserSupport
  module CategoryHandler
    def check_donor_categories_tree
      @donor_category_logger ||= init_logger
      @donor_category_logger.info("[#{Time.zone.now.to_s}] --- Start #{@donor.domain} categories update --- ")

      @donor.donor_categories.where(active: true).each do |donor_category|
        url = "#{@donor.url}#{donor_category.path}"
        puts "Starting to get category: #{url}"

        check_donor_category_path(donor_category)
      end

      @donor_category_logger.info("[#{Time.zone.now.to_s}] --- Finished #{@donor.domain} categories update;")
    end

    def check_donor_category_path(donor_category)
      tryouts = 0
      url = "#{@donor.url}#{donor_category.path}"

      begin
        response = @agent.get(url)
      rescue Exception => e
        tryouts += 1

        if tryouts >= 5
          not_found_donor_category_action(donor_category)
          return false
        else
          @agent.shutdown
          @agent = init_agent
          sleep(3)
          retry
        end
      end

      if response.code[/404/]
        puts "Page expired!"
        puts "url: #{url}"
        not_found_donor_category_action(donor_category)
      elsif response.code[/30[12]/] # 301, 302 redirects
        puts "Page redirected! #{response.code}"
        puts "redirect url: #{response.header['location']}"
        begin
          new_url = response.header['location']
          new_path = URI.parse(new_url).path
        rescue
          new_path = nil
          not_found_donor_category_action(donor_category)
        end

        redirect_donor_category_action(donor_category, new_url)
      end
    end

    private

    def redirect_donor_category_action(donor_category, new_url =nil)
      return false if donor_category.nil? || new_url.nil?

      new_path = URI.parse(new_url).path

      Chewy.strategy(:sidekiq)
      donor_category.update(path: new_path) if !new_path.nil? && !Parser::DRY_RUN
      @donor_category_logger.info("[#{Time.zone.now.to_s}] Update donor_category path because of redirect #{donor_category.path} category; id: #{donor_category.id};")
    end

    def not_found_donor_category_action(donor_category)
      @donor_category_logger.info("[#{Time.zone.now.to_s}] Remove #{donor_category.path} category; id: #{donor_category.id};")
      Chewy.strategy(:sidekiq)
      donor_category.safe_destroy unless Parser::DRY_RUN
    end

    def init_logger
      ActiveSupport::Logger.new("#{Rails.root}/log/category_updator.log")
    end

  end

end
