# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_field_groups
#
#  id          :integer          not null, primary key
#  description :text
#  key         :string
#  position    :integer          default(0)
#  record_type :string
#  repeat      :boolean          default(FALSE)
#  title       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :integer
#
# Indexes
#
#  index_simple_cms_field_groups_on_record  (record_type,record_id)
#

module GacoCms
  class FieldGroup < ApplicationRecord
    include UnionScope
    include BuddyTranslatable
    translatable :title, :description

    belongs_to :record, polymorphic: true
    has_many :fields, -> { ordered }, dependent: :destroy

    scope :ordered, -> { order(position: :asc) }
    accepts_nested_attributes_for :fields, allow_destroy: true

    def available_records
      map_data = ->(item) { [item.title, "#{item.class.name}/#{item.id}"] }
      {
        Page.human_name(count: 2) => GacoCms::Page.title_ordered.select(:title, :id).map(&map_data),
        'All Pages Under' => PageType.title_ordered.select(:title, :id).map(&map_data),
        Theme.human_name(count: 2) => GacoCms::Theme.ordered.map(&map_data)
      }
    end

    def selected_record
      "#{record_type}/#{record_id}"
    end

    def record_label
      return "All pages under \"#{record.title}\"" if record_type.include?('PageType')

      "#{record.class.human_name} => \"#{record.title}\""
    end
  end
end
