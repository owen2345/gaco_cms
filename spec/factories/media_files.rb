# frozen_string_literal: true

require_relative '../factorybot/helpers'
FactoryBot.define do
  factory :media_file, class: 'GacoCms::MediaFile' do
    sequence(:name) { |i| "Media #{i}" }
    transient do
      file_name { 'sample.jpg' }
      source_name { 'sample-photo.jpg' }
    end

    file do
      {
        io: File.open(File.join(__dir__, '../spec/fixtures', source_name)),
        filename: file_name
      }
    end
  end
end
