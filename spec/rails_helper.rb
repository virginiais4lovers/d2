# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

## Custom additions
require 'capybara'
require 'spree/testing_support/factories'
require 'support/factories'

require 'support/devise'
require 'support/subscription_data'

require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {timeout: 90})
end

Capybara.javascript_driver = :poltergeist

require 'capybara-screenshot/rspec'
Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  "screenshot_#{example.description.gsub(' ', '-').gsub(/^.*\/spec\//,'')}"
end
if ENV['CIRCLE_ARTIFACTS'].present?
  Capybara.save_and_open_page_path = ENV['CIRCLE_ARTIFACTS']
  Capybara::Screenshot::RSpec.add_link_to_screenshot_for_failed_examples = false
end
Capybara::Screenshot.webkit_options = { width: 1440, height: 900 }
Capybara::Screenshot.prune_strategy = { keep: 100 }
## END Custom additions

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  ## Configure DatabaseCleaner correctly for Capybara
  config.before(:suite) do
    if config.use_transactional_fixtures?
      raise(<<-MSG)
        Delete line `config.use_transactional_fixtures = true` from rails_helper.rb
        (or set it to false) to prevent uncommitted transactions being used in
        JavaScript-dependent specs.

        During testing, the app-under-test in the browser uses a different database
        connection than the one used by the spec driver. The app's database connection
        cannot access uncommitted transaction data set up by the spec's database
        connection.
      MSG
    end
    DatabaseCleaner.clean_with(:truncation)

    Rails.application.load_tasks # required for db/seeds due to Spree engines
    ENV['INCLUDE_SAMPLES'] = '1'
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:all, with: :seeds) do
    require Rails.root.join('db/seeds')
  end

  config.before(:each, type: :feature) do
    require Rails.root.join('db/seeds')

    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    if !driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      DatabaseCleaner.strategy = :truncation, {:except => %w[
        spree_countries
        spree_states
        spree_postal_codes
        spree_zone_members
        spree_zones
        spree_shipping_method_zones
        spree_shipping_methods
        spree_shipping_method_categories
        spree_shipping_categories
        spree_delivery_windows
        spree_stock_locations
        spree_stores

        spree_calculators
        spree_payment_methods

        spree_taxonomies
        spree_taxons
        spree_prototype_taxons
        spree_prototypes
        spree_property_prototypes
        spree_properties
      ]}
    end
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
  ## END DatabaseCleaner

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Note: Rails 4.1 the default test environment is not threadsafe. If you experience
  # random errors about missing constants, add config.allow_concurrency = false to
  # config/environments/test.rb.

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
