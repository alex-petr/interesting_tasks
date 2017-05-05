Rails.application.routes.draw do
  controller :errors do
    # Connect requests to error pages, served from /<error code> to the appropriate actions of the errors controller.
    match '/404'          => :not_found,             via: :all
    match '/500'          => :internal_server_error, via: :all
    post '/error-message' => :send_message
    post '/'              => :not_found
    match '*any'          => :not_found,             via: :all
  end
end
