# frozen_string_literal: true

# Gaco CMS settings
GacoCms::Config.admin_title = 'My Blog'
GacoCms::Config.url_path = '/blog'
GacoCms::Config.parent_front_controller = 'ActionController::Base'
GacoCms::Config.parent_backend_controller = 'ActionController::Base'
GacoCms::Config.front_layout = ->(_controller) { 'layouts/gaco_cms/front' }
GacoCms::Config.table_prefix = 'gaco_cms_'
GacoCms::Config.locales = [:en, :de, :es] # Rails.configuration.i18n.available_locales
#GacoCms::Config.backend_editor_css = 'gaco_cms_front'
# GacoCms::Config.home_page_key = 'home'
# GacoCms::Config.add_extra_field(:my_field, { tpl: '..', label: 'My field', translatable: true })
# GacoCms::Config.extra_shortcodes = {}
