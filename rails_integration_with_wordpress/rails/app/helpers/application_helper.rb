module ApplicationHelper
  ##
  # Print multiple strings to console with error colored marker.
  # @param [Array] errors
  def console_error(*errors)
    errors.each { |error| puts "\e[31;1m[ERROR]\e[0m #{error}" }
  end

  ##
  # Print multiple strings to console with info colored marker.
  # @param [Array] infos
  def console_info(*infos)
    infos.each { |info| puts "\e[34;1m[INFO]\e[0m #{info}" }
  end

  ##
  # Print multiple strings to console with success colored marker.
  # @param [Array] successes
  def console_success(*successes)
    successes.each { |success| puts "\e[32;1m[SUCCESS]\e[0m #{success}" }
  end

  ##
  # Fetch blog posts from WordPress REST API.
  # @param [String] cache_name
  # @param [Integer] limit
  # @param [String] source
  def fetch_blog_posts(cache_name, limit = nil, source = nil)
    Rails.cache.fetch(cache_name, expires_in: 1.hour) do
      action_message = 'Fetching posts from WordPress API'
      blog_posts = []

      api_url =
        "#{Rails.application.secrets.blog_api_url}posts.php?secret=#{Rails.application.secrets.blog_secret_api_key}"
      api_url << "&count=#{limit}" if limit.present?
      api_url << "&source=#{source}" if source.present?

      begin
        api_json_response = Net::HTTP.get(URI api_url)

        # 1. Forcibly convert string to UTF-8 (probably from ASCII-8BIT) to avoid
        # `Encoding::CompatibilityError < EncodingError incompatible character encodings: ASCII-8BIT and UTF-8`
        #
        # 2. Remove Byte Order Mark (BOM):
        # UTF-8: EF BB BF = \xEF\xBB\xBF
        # UTF-16 (BE): FE FF = \uFEFF
        # to avoid `JSON::ParserError < JSON::JSONError 757: unexpected token at '﻿{"success":true,"messages"...`
        #
        # 3. Deserialize JSON string to OpenStruct object.
        response = JSON.parse(api_json_response.force_encoding('UTF-8').sub("\uFEFF", ''), object_class: OpenStruct)

        console_info api_url
        if response.success
          console_success action_message
          console_success response.messages.success.join(' ')
          blog_posts = response.posts
        else
          console_error action_message
          console_error response.messages.error.join(' ')
        end
      rescue Exception => error
        console_info api_url
        console_error action_message
        console_error "\e[34;1m#{error.class} < #{error.class.superclass.name}\e[0m \e[31;1m#{error.message}\e[0m"
      ensure
        blog_posts
      end
    end
  end
end
