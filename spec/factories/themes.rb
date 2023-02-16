# frozen_string_literal: true

require_relative '../factorybot/helpers'
FactoryBot.define do
  factory :theme, class: 'GacoCms::Theme' do
    sequence(:key) { |i| "key-#{i}" }
    title { fake_translation }
    active { true }
  end
end
