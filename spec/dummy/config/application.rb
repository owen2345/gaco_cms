require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require "gaco_cms"
require 'factory_bot_rails'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")


    # define available locales
    I18n.available_locales = [:en, :es]
    I18n.locale = :en

    # define engine factories
    engine_dir = File.expand_path('../../../../', __FILE__)
    config.factory_bot.definition_file_paths += [File.join(engine_dir, 'spec/factories')]
  end
end
