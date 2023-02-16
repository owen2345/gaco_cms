# frozen_string_literal: true

require_relative '../factorybot/helpers'
FactoryBot.define do
  factory :field_value, class: 'GacoCms::FieldValue' do
    value { fake_translation }
    group_no { 0 }
    sequence(:position) { |i| i }
    record { create(:page) }
    field { field_key ? create(:field, key: field_key) : create(:field) }
  end
end
