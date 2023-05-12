# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_fields
#
#  id             :integer          not null, primary key
#  data           :text
#  def_value      :text
#  description    :text
#  key            :string
#  kind           :string           default("text_field")
#  position       :integer          default(0)
#  repeat         :boolean          default(FALSE)
#  required       :boolean          default(FALSE)
#  title          :text
#  translatable   :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  field_group_id :integer          not null
#
# Indexes
#
#  index_simple_cms_fields_on_field_group_id  (field_group_id)
#
# Foreign Keys
#
#  field_group_id  (field_group_id => simple_cms_field_groups.id)
#

module GacoCms
  class Field < ApplicationRecord
    include BuddyTranslatable
    translatable :title, :description, :def_value

    EXTRA_KINDS = GacoCms::Config.extra_fields
    KINDS = %i[text_field text_area editor file page].concat(EXTRA_KINDS.keys)
    enum kind: KINDS.map { |k| [k, k.to_s] }.to_h

    belongs_to :field_group, optional: false
    has_many :field_values, dependent: :destroy, inverse_of: :field
    after_update_commit :update_values_key, if: :saved_change_to_key?

    validates :key, uniqueness: { scope: :field_group_id }
    scope :ordered, -> { order(position: :asc) }

    def self.dropdown_data
      KINDS.map do |key|
        title = key.to_s.titleize
        title = ApplicationHelper.translated_value_for(EXTRA_KINDS[key][:label]) if EXTRA_KINDS[key]
        [title, key]
      end
    end

    def default_value_tpl
      return "/gaco_cms/admin/field_groups_renderer/default_value/#{kind}" if kind == 'page'

      EXTRA_KINDS.dig(kind&.to_sym, :default_value_tpl)
    end

    def allow_translation?
      return false if %w[page].include?(kind)

      res = EXTRA_KINDS.dig(kind&.to_sym, :translatable)
      res.nil? ? true : res
    end

    def tpl
      EXTRA_KINDS.dig(kind&.to_sym, :tpl) || "/gaco_cms/admin/field_groups_renderer/fields/#{kind}"
    end

    private

    def update_values_key
      field_values.each { |v| v.update!(field_key: key) }
    end
  end
end
