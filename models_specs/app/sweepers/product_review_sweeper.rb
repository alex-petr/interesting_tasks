class ProductReviewSweeper < ActionController::Caching::Sweeper
  observe ProductReview

  ##
  # Callback called for model create, update or destroy.
  def after_commit(record)
    expire_homepage_products_cache
  end

  ##
  # Delete homepage best products blocks cache by categories.
  # @see HomeHelper#best_products_by_category
  # @param [Array Category] categories
  def expire_homepage_products_cache
    Category.roots.each { |category| Rails.cache.delete("/category_#{category.id}/best_products") }
  end
end
