# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_pages
#
#  id           :integer          not null, primary key
#  content      :text
#  key          :text
#  photo_url    :text
#  summary      :text
#  template     :text
#  title        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  page_type_id :integer          not null
#
# Indexes
#
#  index_simple_cms_pages_on_page_type_id  (page_type_id)
#
# Foreign Keys
#
#  page_type_id  (page_type_id => simple_cms_page_types.id)
#

module GacoCms
  class Page < ApplicationRecord
    include BuddyTranslatable
    include GacoCms::FieldsAssignable
    translatable :key, :title, :summary, :content

    belongs_to :page_type
    scope :title_ordered, -> { order(title: :asc) }

    def self.by_key(key)
      where_key_with(key).take
    end

    def the_content(cache: true)
      callback = proc do
        tpl = template.presence || page_type.template.to_s
        tpl = "[page_content]#{tpl}" unless tpl.include?('[page_content]')
        ShortcodeParser.call(tpl, self).to_s
      end
      return callback.call unless cache

      Rails.cache.fetch("#{cache_prefix_for(id)}/the_content", expires_at: Time.current.end_of_day, &callback)
    end

    def the_path(parented: true, titled: true)
      if parented
        Rails.cache.fetch("#{cache_prefix_for(page_type_id)}/the_path", expires_at: Time.current.end_of_day) do
          Rails.application.routes.url_helpers.gaco_cms_type_titled_page_path(type_title: page_type.title.parameterize, page_title: title.parameterize, page_id: id)
        end
      elsif titled
        Rails.application.routes.url_helpers.gaco_cms_titled_page_path(page_title: title.parameterize, page_id: id)
      else
        Rails.application.routes.url_helpers.gaco_cms_page_path(page_id: key)
      end
    end
  end
end
