desc 'Reprocess product images for FaceBook Bot'
task :images_fb_bot_refresh, [:start_id] => :environment do |_, args|
  separator             = "\n#{'-' * 65}"
  processed_count       =
    total_processing_time = 0
  helper                = ApplicationController.helpers
  product_images        = ProductImage.where.not(image_file_name: nil)
  count                 = product_images.count
  start_id              = args[:start_id].to_i
  start_from_message    = ''

  format_time = -> (time) do
    time_utc = Time.at(time).utc
    time_utc.strftime("#{(time_utc.strftime('%d').to_i - 1).to_s.rjust(2, '0')}d:%Hh:%Mm:%Ss:%Lms")
  end
  green_text            = -> (text) { "\e[32;1m#{text}\e[0m" }
  blue_text             = -> (text) { "\e[34;1m#{text}\e[0m" }
  red_text              = -> (text) { "\e[31;1m#{text}\e[0m" }

  unless start_id.zero?
    product_image_ids = product_images.order(:id).pluck :id
    count -= product_image_ids.index start_id # Offset total images count by image id index number.
    product_image_ids = nil # Free memory.
    start_from_message = "Start id = #{blue_text.call start_id} "
  end

  helper.console_info 'Reprocess product images for FaceBook Bot task started!',
                      "#{start_from_message}Total images count: #{green_text.call count}#{separator}"

  time_elapsed = Benchmark.realtime do
    product_images.find_each start: start_id do |product_image|
      processed_count += 1

      total_info   = "#{processed_count} / #{count} = #{(processed_count * 100.0 / count).round 3}%"
      total_info   = "Images processed: #{green_text.call total_info}#{separator}"
      current_info = "ProductImage: id = #{blue_text.call product_image.id}"

      begin
        start_time = Time.now

        if product_image.image.exists?
          product_image.image.reprocess! :fb_bot
          helper.console_success current_info
        else
          helper.console_error current_info + ' not exists and skipped'
        end
      rescue Exception => error # In case of unknown error.
        helper.console_error current_info + " #{error.class} < #{error.class.superclass.name} #{error.message}"
      ensure
        helper.console_info total_info
      end

      # Time estimate by summing up all time spent divided by count of processed images.
      total_processing_time += (Time.now - start_time)
      time_left = (count - processed_count) * (total_processing_time / processed_count)

      if 0 == processed_count % 25
        helper.console_info "Approximately time left: #{green_text.call(format_time.call time_left)}#{separator}"
      end
    end
  end
  helper.console_info "Time elapsed for images processing: #{green_text.call(format_time.call time_elapsed)}"
end
