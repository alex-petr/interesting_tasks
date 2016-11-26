module HomeHelper
  def best_products_by_category(category)
    Rails.cache.fetch("/category_#{category.id}/best_products", expires_in: 1.hour) do
      best_product_ids = Product
                           .joins(:categories_products)
                           .includes(:donor_products)
                           .where('categories_products.category_id = ?', category.id)
                           .group('products.id')
                           .order('donor_products_count DESC, max_discount DESC')
                           .limit(20)
                           .pluck(:id)

      featured_product_ids = Product
                               .joins(:categories_products)
                               .includes(:donor_products)
                               .where('categories_products.category_id = ? AND products.featured IS TRUE', category.id)
                               .group('products.id')
                               .order('donor_products_count DESC, max_discount DESC')
                               .limit(20)
                               .pluck(:id)

      best_products     = Product.includes(:donor_products, :product_images).where(id: best_product_ids)
      featured_products = Product.includes(:donor_products, :product_images).where(id: featured_product_ids)

      homepage_products = featured_products + best_products.shuffle

      homepage_products.uniq.take 4
    end
  end
end
