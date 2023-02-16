# frozen_string_literal: true

require_relative '../factorybot/helpers'
FactoryBot.define do
  factory :field, class: 'GacoCms::Field' do
    sequence(:key) { |i| "key-#{i}" }
    title { fake_translation }
    description { fake_translation }
    data { fake_translation }
    def_value { fake_translation }
    repeat { false }
    required { true }
    translatable { true }
    kind { 'text_field' }
    sequence(:position) { |i| i }
    field_group

    trait :text_field do
      kind { :text_field }
    end

    trait :page do
      kind { :page }
    end

    trait :text_area do
      kind { :text_area }
    end

    trait :with_values do
      after(:create) do |field, _ev|
        field.field_values = create_list(:field_value, 1, field: field)
      end
    end
  end
end
