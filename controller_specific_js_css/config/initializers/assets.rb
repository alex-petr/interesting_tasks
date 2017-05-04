Dir[Rails.root.join('app', 'assets', '**', '*.{coffee,css,scss}')].each do |file|
  Rails.application.config.assets.precompile << file
end
