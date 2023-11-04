# frozen_string_literal: true

class CmsAddTemplateToFields < ActiveRecord::Migration[7.0]
  def change
    add_column GacoCms::Field.table_name, :template, :text, default: ''
  end
end
