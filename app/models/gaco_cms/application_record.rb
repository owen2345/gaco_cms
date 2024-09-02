# frozen_string_literal: true

module GacoCms
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    after_save_commit { self.class.cache_prefix_for(id, force: true) } # saves the cache key with the last update time
    delegate :cache_prefix_for, to: 'self.class'

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

      def cache_prefix_for(id, force: false)
        GacoCms::Config.locales.each { |loc| Rails.cache.delete("#{self.name}/#{loc}/#{id}/last_update") } if force

        Rails.cache.fetch("#{self.name}/#{I18n.locale}/#{id}/last_update", expires_in: 1.week) do
          "#{self.name}/#{id}/#{Time.current.to_i}"
        end
      end
    end
  end
end
