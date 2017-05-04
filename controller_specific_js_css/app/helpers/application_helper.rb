module ApplicationHelper
  def styles_to_load
    styles_list = ''
    current_controller = params[:controller].gsub('/', '_')
    if File.exist? Rails.root.join('app', 'assets', 'stylesheets', "#{current_controller}.scss")
      styles_list << current_controller
    end
    styles_list
  end

  def scripts_to_load
    scripts_list = ''
    current_controller = params[:controller].gsub('/', '_')
    if File.exist? Rails.root.join('app', 'assets', 'javascripts', "#{current_controller}.coffee")
      scripts_list << current_controller
    end
    scripts_list
  end
end
