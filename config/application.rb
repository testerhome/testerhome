# coding: utf-8
require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"
require 'sprockets/railtie'

if defined?(Bundler)
  Bundler.require *Rails.groups(assets: %w(production development test))
end

module TesterHome
  class Application < Rails::Application
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/uploaders)
    config.autoload_paths += %W(#{config.root}/lib)
    config.eager_load_paths += [
        Rails.root.join('lib/homeland'),
        Rails.root.join('lib/exception_notifier')
    ]
    config.autoload_paths += %W(#{config.root}/app/grape)

    config.time_zone = 'Beijing'

    # The default locale is :zh-CN and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = 'zh-CN'
    config.i18n.available_locales = ['zh-CN', 'en', 'zh-TW']
    config.i18n.fallbacks = true
    config.middleware.use I18n::JS::Middleware

    config.autoload_paths << Rails.root.join("app/api")
    config.autoload_paths << Rails.root.join('lib')

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    config.mongoid.include_root_in_json = false



    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end

    config.action_view.sanitized_allowed_attributes = %w{target}

    config.to_prepare {
      Devise::Mailer.layout "mailer"
      # Only Applications list
      Doorkeeper::ApplicationsController.layout "simple"
      # Only Authorization endpoint
      Doorkeeper::AuthorizationsController.layout "simple"
      # Only Authorized Applications
      Doorkeeper::AuthorizedApplicationsController.layout "simple"
    }

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '/api/*', headers: :any, methods: [:get, :post, :put, :delete, :destroy]
        resource '/oauth/*', headers: :any, methods: [:get, :post, :put, :delete, :destroy]
      end
    end

    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    config.cache_store = [:dalli_store,"127.0.0.1", { namespace: "th", compress: true }]

    config.middleware.insert 0, Rack::UTF8Sanitizer
    config.active_job.queue_adapter = :sidekiq
  end
end

$memory_store = ActiveSupport::Cache::MemoryStore.new

I18n.config.enforce_available_locales = false
I18n.locale = 'zh-CN'

# GC::Profiler.enable