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

require 'byebug'
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

    def all_field_groups
      FieldGroup.union_scope(field_groups, page_type.field_groups)
    end

    def the_content
      Rails.cache.fetch(cache_key_locale(:the_content), expires_at: Time.current.end_of_day) do
        tpl = template.presence || page_type.template.to_s
        tpl = "[page_content]#{tpl}" unless tpl.include?('[page_content]')
        ShortcodeParser.call(tpl, self).to_s
      end
    end
  end
end
