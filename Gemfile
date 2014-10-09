source 'https://rubygems.org'

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.15'


gem 'rails', '3.2.19'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'whenever', :require => false
gem 'pdf-reader'
gem 'tabula-extractor', '0.7.5'
gem 'will_paginate', '~> 3.0'

gem 'activerecord-jdbc-adapter'

group :development do
	gem 'jdbc-sqlite3'
	gem 'activerecord-jdbcsqlite3-adapter'
end

group :production, :test do
	gem 'jdbc-postgres'
	gem 'activerecord-jdbcpostgresql-adapter'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
