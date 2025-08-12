# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'active_job/test_helper'
require 'factory_bot_rails'
require 'shoulda/matchers'

RSpec.configure do |config|
  # FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # ActiveJob helpers
  config.include ActiveJob::TestHelper

  config.before(:suite) do
    ActiveJob::Base.queue_adapter = :test
  end

  # Only needed if you still use Rails fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true

  ActiveRecord::Migration.maintain_test_schema!

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

# Shoulda Matchers config
Shoulda::Matchers.configure do |shoulda_config|
  shoulda_config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
