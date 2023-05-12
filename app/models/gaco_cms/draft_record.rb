# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_cms_draft_records
#
#  id          :integer          not null, primary key
#  record_type :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module GacoCms
  class DraftRecord < ApplicationRecord
    include GacoCms::FieldsAssignable
  end
end
