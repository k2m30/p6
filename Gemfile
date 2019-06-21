source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '>= 5.2.2.1'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
# gem 'uglifier', '>= 1.3.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
gem 'web-console', '>= 3.3.0', group: [:development, :production]

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring','~> 2.0'
  gem 'spring-watcher-listen', '~> 2.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'haml', '~> 5.0'
gem 'haml-rails', '~> 1.0', require: false
gem 'bootstrap', '~> 4.3'
gem 'jquery-rails', '~> 4.3'
gem 'redis', '~> 4.0'
gem 'rack-mini-profiler', '~> 1.0'#, require: false
gem 'numo-gnuplot'

group :test do
  gem 'minitest','~> 5.11'
  gem "minitest-rails"
  gem 'minitest-reporters'
  gem 'simplecov'
end