# frozen_string_literal: true

require_relative '../factorybot/helpers'
FactoryBot.define do
  factory :page, class: 'GacoCms::Page' do
    sequence(:key) { |i| "key-#{i}" }
    sequence(:title) { |index| fake_translation("Title #{index}") }
    sequence(:summary) { |index| fake_translation("Summary #{index}") }
    sequence(:content) { |index| fake_translation("Content #{index}") }
    template { '' }
    page_type
    photo_url { 'https://static.remove.bg/sample-gallery/graphics/bird-thumbnail.jpg' }
  end
end
