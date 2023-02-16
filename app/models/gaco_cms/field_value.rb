# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_field_values
#
#  id          :integer          not null, primary key
#  field_key   :string
#  group_no    :integer          default(0)
#  position    :integer          default(0)
#  record_type :string
#  value       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  field_id    :integer          not null
#  record_id   :integer
#
# Indexes
#
#  index_simple_cms_field_values_on_field_id  (field_id)
#  index_simple_cms_field_values_on_record    (record_type,record_id)
#
# Foreign Keys
#
#  field_id  (field_id => simple_cms_fields.id)
#

module GacoCms
  class FieldValue < ApplicationRecord
    include BuddyTranslatable
    translatable :value

    belongs_to :record, polymorphic: true, touch: true
    belongs_to :field, optional: false
    before_validation :retrieve_field_key, unless: :field_key
    validates :field_key, presence: true
    validates :record, presence: true

    scope :for_group, ->(group) { joins(:field).merge(GacoCms::Field.where(field_group_id: group.id)) }
    scope :ordered, -> { order(position: :asc) }
    delegate :translatable, :repeat, :required, :kind, :def_value, :def_value_data, to: :field

    def self.group_nos_for(group)
      for_group(group).pluck(:group_no).uniq.sort
    end

    def self.all_or_new_for(field, group_no)
      items = where(field: field).where(group_no: group_no)
      items.any? ? items.ordered : [items.new]
    end

    def self.grouped
      groups = reorder(group_no: :asc).pluck('distinct(group_no)')
      groups.map do |g_no|
        where(group_no: g_no).ordered
      end
    end

    def value_for_input
      @value_for_input ||= begin
        return new_record? ? def_value : value unless translatable

        new_record? ? def_value_data.to_json : value_data.to_json
      end
    end

    def the_value
      ShortcodeParser.call(value, record)
    end

    private

    def retrieve_field_key
      self.field_key = field.key
    end
  end
end
