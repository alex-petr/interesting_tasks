class CategorySweeper < ActionController::Caching::Sweeper
  observe Category

  def after_save(record)
    ApplicationController.expire_page(Rails.application.routes.url_helpers.root_path)
  end

  def after_destroy(record)
    ApplicationController.expire_page(Rails.application.routes.url_helpers.root_path)
  end
end
