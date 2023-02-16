# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_media_files
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

module GacoCms
  class MediaFile < ApplicationRecord
    has_one_attached :file # TODO: if image, then create a thumb version 100x100
    validates :file, presence: true

    def url
      activestorage_url(file)
    end
  end
end
