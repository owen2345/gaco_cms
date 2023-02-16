# frozen_string_literal: true

module GacoCms
  class Config
    cattr_accessor(:url_path) { '/gaco_cms' }
    cattr_accessor(:parent_front_controller) { 'ActionController::Base' }
    cattr_accessor(:parent_backend_controller) { 'ActionController::Base' }
    cattr_accessor(:front_layout) { ->(_controller) { theme_path_for('layouts/application') } }
    cattr_accessor(:backend_editor_css) { ->(_view) { asset_path('application') } }
    cattr_accessor(:table_prefix) { 'simple_cms_' } # TODO: rename into gaco_cms_
    cattr_accessor(:locales) { %i[en de es] }
    cattr_accessor(:extra_fields) { {} }

    # @param settings [Hash<:tpl, :translatable, :label, :default_value_tpl?>]
    def self.add_extra_field(key, settings)
      extra_fields[key] = settings
    end
  end
end
