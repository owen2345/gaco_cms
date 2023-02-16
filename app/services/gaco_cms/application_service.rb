# frozen_string_literal: true

module GacoCms
  class ApplicationService
    def initialize(*args); end

    class << self
      # @see #initialize
      def call(*args, **kwargs)
        new(*args, **kwargs).call
      end

      # Code style definition for Sidekiq delay method
      # @!method delay(settings = {})
      #   @param [Hash] settings
      #   @return [self] returns itself
    end

    private

    #
    # @param [String] message
    # @param [:info|:warn|:error] mode
    #
    def log(message, mode: :info)
      Rails.logger.send(mode, "#{self.class.name} => #{message}")
    end

    def print_error(error)
      log("Failed with #{error.message}. #{error.backtrace[0..10]}")
    end
  end
end
