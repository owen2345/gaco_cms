# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_themes
#
#  id         :integer          not null, primary key
#  active     :boolean          default(FALSE)
#  key        :string           not null
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

module GacoCms
  class Theme < ApplicationRecord
    include GacoCms::FieldsAssignable

    validates :key, presence: true
    validates :title, presence: true, uniqueness: true

    scope :ordered, -> { order(title: :asc) }

    def self.current
      find_by(active: true)
    end
  end
end
