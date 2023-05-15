# frozen_string_literal: true

module GacoCms
  module FieldsAssignable
    extend ActiveSupport::Concern
    included do
      has_many :field_groups, -> { ordered }, as: :record, inverse_of: :record, dependent: :destroy
      has_many :fields, through: :field_groups
      has_many :field_values, dependent: :destroy, as: :record, inverse_of: :record
      accepts_nested_attributes_for :field_values, allow_destroy: true
      accepts_nested_attributes_for :field_groups, allow_destroy: true
    end

    def the_value(key, cache: true)
      callback = proc { field_values.ordered.find_by(field_key: key)&.the_value }
      return callback.call unless cache

      Rails.cache.fetch(cache_key_locale(:the_value, key), expires_at: Time.current.end_of_day, &callback)
    end

    def default_group
      @default_group ||= field_groups.where(key: :default).first_or_create(title: 'Basic Fields', key: :default)
    end

    def the_values(key, cache: true)
      callback = proc { field_values.ordered.where(field_key: key).map(&:the_value) }
      return callback.call unless cache

      Rails.cache.fetch(cache_key_locale(:the_values, key), expires_at: Time.current.end_of_day, &callback)
    end

    def the_grouped_values(*keys, cache: true)
      callback = proc do
        field_values.where(field_key: keys).grouped.map do |fields|
          fields.map { |f| [f.field_key, f.the_value] }.to_h
        end
      end
      return callback.call unless cache

      cache_key = cache_key_locale(:the_grouped_values, keys.join('-'))
      Rails.cache.fetch(cache_key, expires_at: Time.current.end_of_day, &callback)
    end
  end
end
