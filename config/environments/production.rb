# coding: utf-8
Rails.application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # Use a different logger for distributed setups
  # config.logger = Logger.new("#{Rails.root}/log/#{Rails.env}.log", 'weekly')
  # config.log_level = :info

  # Use a different cache store in production
  config.cache_store = [:dalli_store,"127.0.0.1", { namespace: "rb-cn", compress: true }]

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false


  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = {:host => "testerhome.com" }
  config.action_mailer.delivery_method =:smtp
  config.action_mailer.smtp_settings = {
    :address=> "smtp.126.com",
    :port=> 25,
    :domain=> "126.com",
    :authentication=> :login,
    :user_name=> "testerhome@126.com",
    :password=> "Testerhome2013"
  }


  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  config.assets.js_compressor  = :uglifier
  config.assets.css_compressor = :scss

  # Do not dump schema after migrations.
  # config.active_record.dump_schema_after_migration = false

  #config.force_ssl = true
end