require 'support/uri_handler'

module ParserSupport
  module ImageHandler
    include ParserSupport::URIHandler

    def image_dhash(image_url)
      begin
        dhash = Dhash.calculate(image_url)
      rescue
        dhash = nil
      end

      dhash
    end

    def remote_file_exists?(url)
      tryouts = 0
      begin
        tryouts += 1
        # for cases with square brackets [ and ] in url
        # encode_url = URI.encode(url).gsub('[', '%5B').gsub(']', '%5D')
        encode_url = URI.encode(url)
        uri = URI.parse(encode_url)
        response = Net::HTTP.get_response(uri)
      rescue Exception => e
        if tryouts < 3

          # Rollbar.error("#{e}\n url: #{url}")
          puts "tryout: #{tryouts}"
          retry
        else
          return false
        end
      end

      response.code.to_i == 200
    end

    def update_image_url(image_url)
      encoded_image_url = uri_encode(image_url)
      encoded_image_url.gsub!('//', 'http://') unless encoded_image_url.include?('http')
      encoded_image_url
    end

    ##
    # Usage:
    #   file_name = img_url.split('/').last
    #   download_path =  "#{Rails.root}/tmp/#{file_name}"
    #   download_image(img_url, download_path)
    #   dhash = image_dhash(download_path)
    #   `rm #{download_path}`
    def download_image(url, path)
      File.open(path, 'wb') do |saved_file|
        open(url, 'rb') { |read_file| saved_file.write(read_file.read) }
      end
    end
  end
end
