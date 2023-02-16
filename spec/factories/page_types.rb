# frozen_string_literal: true

require_relative '../factorybot/helpers'
FactoryBot.define do
  factory :page_type, class: 'GacoCms::PageType' do
    sequence(:key) { |i| "key-#{i}" }
    title { fake_translation }
    template { '' }
  end
end
