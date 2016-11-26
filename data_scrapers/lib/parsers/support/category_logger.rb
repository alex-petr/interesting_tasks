module ParserSupport
  class CategoryLogger
    LOG_FILES = %w(donor_category_pages failed_donor_products saved_donor_products other) unless defined?(LOG_FILES)
    BASE_PATH = "#{Rails.root}/log/scrappers" unless defined?(BASE_PATH)

    def initialize(donor_category)
      @donor_category_path = "#{BASE_PATH}/#{donor_category.donor.domain}/category_#{donor_category.id}/"

      create_directory(@donor_category_path)
      init_log_files
    end

    # create files and init variables of log files
    def init_log_files
      LOG_FILES.each do |filename|
        log_variable = "@#{filename}_log"
        log_file = ActiveSupport::Logger.new("#{@donor_category_path}/#{filename}.log")

        instance_variable_set(log_variable, log_file) unless instance_variable_defined?(log_variable)
        self.class.send(:attr_accessor, "#{filename}_log")
      end
    end

    private

    # directory for logs
    def create_directory(dir_name)
      FileUtils::mkdir_p dir_name unless File.exists?(dir_name)
    end

  end
end
