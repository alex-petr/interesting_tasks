class StaticPagesController < ApplicationController
  layout 'static_pages'
  BLOG_LIMIT = 4

  def pokemon_calculator
    @title                 = I18n.t('title.pokemon_calculator_page')
    @keywords              = I18n.t('keywords.pokemon_calculator_page')
    @description           = I18n.t('description.pokemon_calculator_page')
    @home_path             = I18n.t('content.breadcrumb')
    @blog_posts_limit      = BLOG_LIMIT
    @blog_posts_cache_name = 'blog_posts_pokemon_go'
    @blog_posts_source     = 'pokemon-go'
  end

  def pokeradar
    @title                 = I18n.t('title.pokeradar_page')
    @description           = I18n.t('description.pokeradar_page')
    @home_path             = I18n.t('article.pokeradar_page')
    @blog_posts_limit      = BLOG_LIMIT
    @blog_posts_cache_name = 'blog_posts_pokemon_go'
    @blog_posts_source     = 'pokemon-go'
  end
end
