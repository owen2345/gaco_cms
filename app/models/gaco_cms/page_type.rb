# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_page_types
#
#  id         :integer          not null, primary key
#  key        :string
#  template   :text             default("")
#  title      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_simple_cms_page_types_on_key  (key)
#

module GacoCms
  class PageType < ApplicationRecord
    include BuddyTranslatable
    translatable :title

    has_many :pages, dependent: :destroy
    has_many :field_groups, -> { ordered }, as: :record, inverse_of: :record, dependent: :destroy
    after_update_commit :touch_pages
    accepts_nested_attributes_for :field_groups, allow_destroy: true

    scope :title_ordered, -> { order(title: :asc) }

    private

    # reset pages cached values
    def touch_pages
      pages.find_each(&:touch)
    end
  end
end
