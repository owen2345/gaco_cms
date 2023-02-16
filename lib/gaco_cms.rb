# frozen_string_literal: true

require 'gaco_cms/version'
require 'gaco_cms/config'
require 'gaco_cms/engine'
require 'buddy_translatable'

module GacoCms
  def self.table_name_prefix
    Config.table_prefix
  end

  def self.translated_column(t_migration, column, **args)
    text_args = {}.merge(args)
    json_args = { default: {} }.merge(args)
    t_migration.respond_to?(:jsonb) ? (t_migration.jsonb column, **json_args) : (t_migration.text column, **text_args)
  end
end
