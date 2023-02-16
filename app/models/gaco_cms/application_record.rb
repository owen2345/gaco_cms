# frozen_string_literal: true

module GacoCms
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    def cache_key_locale(*keys)
      "#{cache_key_with_version}/#{I18n.locale}/#{keys.join('-')}"
    end

    def activestorage_url(file)
      return '' unless file&.blob
      return file.url.split('?').first if file.service.name == :amazon

      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    end

    class << self
      alias attr_label human_attribute_name
      def human_name(args = {})
        model_name.human(args)
      end
    end
  end
end
