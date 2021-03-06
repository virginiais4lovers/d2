require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module D2
  class Application < Rails::Application

    config.to_prepare do
      # Load application's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # Load application's view overrides
      Dir.glob(File.join(File.dirname(__FILE__), "../app/overrides/*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    # Configure logging
    console do
      ActiveRecord::Base.logger = Rails.logger = RailsStdoutLogging::Rails.heroku_stdout_logger
    end
    config.lograge.enabled = Rails.env.production?
    exclude_keys = ['controller', 'action', 'utf8']
    config.lograge.custom_options = lambda do |event|
      params = event.payload[:params].except(*exclude_keys)
      {
        'request_id' => event.payload[:request_id],
        'remote_ip' => event.payload[:remote_ip],
        'params' => params,
      }
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # TODO: Make time zone dynamic before expanding beyond the west coast
    config.time_zone = 'Pacific Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Allow any origin to load fonts
    # TODO: tighten this up in production
    config.font_assets.origin = '*'

    ::TRUE_PRODUCTION_INSTANCE = false # Set to true under the right conditions in production.rb
  end
end
