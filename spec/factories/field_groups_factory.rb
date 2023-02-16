# frozen_string_literal: true

require_relative '../factorybot/helpers'
FactoryBot.define do
  factory :field_group, class: 'GacoCms::FieldGroup' do
    sequence(:key) { |i| "key-#{i}" }
    title { fake_translation }
    description { fake_translation }
    record { create(:page_type) }
    repeat { false }
    sequence(:position) { |i| i }

    trait :with_fields do
      transient do
        qty_fields { 1 }
      end

      after(:create) do |model, ev|
        model.fields = create_list(:field, ev.qty_fields, field_group: model)
      end
    end
  end
end
