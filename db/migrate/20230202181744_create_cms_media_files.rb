# frozen_string_literal: true

class CreateCmsMediaFiles < ActiveRecord::Migration[7.0]
  def change
    create_table GacoCms::MediaFile.table_name do |t|
      t.string :name
      t.timestamps
    end
  end
end
