# coding: utf-8
if ENV['USE_OFFICIAL_GEM_SOURCE']
  source 'https://rubygems.org'
else
  source 'https://ruby.taobao.org'
end

gem 'rails', '4.2.4'
gem 'sprockets', '~> 3.3.3'
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'jbuilder'

gem 'turbolinks', github: 'rails/turbolinks'
gem 'jquery-turbolinks'

gem 'actionpack-action_caching', '1.1.1'
gem 'rails-i18n'
gem 'rails_autolink', '>= 1.1.0'
gem 'md_emoji', '1.0.2'
gem 'exception_notification'

gem 'doorkeeper'
gem "doorkeeper-mongodb", github: "doorkeeper-gem/doorkeeper-mongodb"
gem 'doorkeeper-i18n'


gem 'rails-perftest'
gem 'ruby-prof'

# 上传组件
gem 'carrierwave', '~> 0.10.0'
gem 'mini_magick'
gem 'rucaptcha'
gem 'letter_avatar'

# Mongoid 辅助插件
gem 'mongoid', '5.0.0'
gem 'mongoid_auto_increment_id', '0.8.1'
gem 'mongoid_rails_migrations'

# 用户系统
gem 'devise', '~> 3.5.1'
gem 'devise-async'
gem 'devise-encryptable', '0.1.2'

gem 'bootstrap_tokenfield_rails'

# 分页
gem 'will_paginate', '3.0.7'


# 三方平台 OAuth 验证登陆
gem 'omniauth', '~> 1.2.2'
gem 'omniauth-github', '~> 1.1.0'

# permission
gem 'cancancan', '~> 1.8.4'

gem 'redis', '~> 3.2.1'
gem 'hiredis', '~> 0.6.0'
# Redis 命名空间
gem 'redis-namespace', '~> 1.5.1'
# 将一些数据存放入 Redis
gem 'redis-objects', '1.1.0'

# Markdown 格式 & 文本处理
gem 'redcarpet', '~> 3.3.3'
gem 'rouge', '~> 1.8.0'
gem 'auto-space', '0.0.4'
gem 'nokogiri', '1.6.5'

# YAML 配置信息
gem 'settingslogic', '~> 2.0.9'

# 队列
gem 'sidekiq', '4.0.0.pre2'

# Sidekiq Web
gem 'sinatra', :require => nil

gem 'message_bus'

# 分享功能
gem 'social-share-button', :git => 'https://github.com/testerhome/social-share-button.git'

# 表单
gem 'simple_form', '3.1.0'

# API
gem 'grape', '0.7.0'
gem 'active_model_serializers'
gem 'grape-active_model_serializers'

# Mailer
gem 'postmark', '0.9.15'
gem 'postmark-rails', '0.4.1'

gem 'god'

# Dalli, kgio is for Dalli
gem 'kgio'
gem 'dalli', '2.7.4'

gem 'thin'

# for api 跨域
gem 'rack-cors', require: 'rack/cors'
gem 'rack-utf8_sanitizer'

# elasticsearch
gem "elasticsearch"
gem "elasticsearch-model"
gem "elasticsearch-rails"
gem 'tilt'

group :development, :test do
  gem 'capistrano', '2.9.0', require: false
  gem 'rvm-capistrano', require: false
  gem 'rspec-rails', '~> 3.1'
  gem 'factory_girl_rails', '1.4.0'
  gem 'database_cleaner'
  gem 'capybara', '~> 2.3.0'
  gem 'api_taster', '0.6.0'
  gem 'letter_opener'
  # Better Errors
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'colorize'
  gem 'jasmine-rails', '~> 0.10.2'
end
