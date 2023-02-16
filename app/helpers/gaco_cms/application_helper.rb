# frozen_string_literal: true

module GacoCms
  module ApplicationHelper
    def form_title(model)
      model.new_record? ? "Edit #{model.class.human_name}" : "New #{model.class.human_name}"
    end

    def page_url_for(id)
      Rails.application.routes.url_helpers.gaco_cms_page_path(page_id: id)
    end
    module_function :page_url_for

    def required_label(form, key, args = {}, &block)
      append = args[:optional] ? capture { block&.call } : "<small>#{capture { block&.call }}(*)</small>"
      form.label(key, args) { |l| "#{args[:label] || l} #{append}".html_safe } # rubocop:disable Rails/OutputSafety
    end

    def self.translated_value_for(data)
      data = { en: data } unless data.is_a?(Hash)
      data[I18n.locale].presence ||
        data[I18n.default_locale].presence ||
        data.values.find(&:present?)
    end
  end
end
