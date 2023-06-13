# frozen_string_literal: true

module GacoCms
  class Config
    cattr_accessor(:url_path) { '/gaco_cms' }
    cattr_accessor(:parent_front_controller) { 'ActionController::Base' }
    cattr_accessor(:parent_backend_controller) { 'ActionController::Base' }
    cattr_accessor(:front_layout) { ->(_controller) { 'layouts/gaco_cms/front' } }
    cattr_accessor(:backend_editor_css) { 'gaco_cms_front' }
    cattr_accessor(:table_prefix) { 'simple_cms_' } # TODO: rename into gaco_cms_
    cattr_accessor(:locales) { %i[en de es] }
    cattr_accessor(:extra_fields) { {} }
    cattr_accessor(:home_page_key) { nil }

    # @param settings [Hash<:tpl, :translatable, :label, :default_value_tpl?>]
    def self.add_extra_field(key, settings)
      extra_fields[key] = settings
    end
  end
end
