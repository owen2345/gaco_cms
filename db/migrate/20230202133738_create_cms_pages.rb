# frozen_string_literal: true

class CreateCmsPages < ActiveRecord::Migration[7.0]
  def change
    create_table GacoCms::Page.table_name do |t|
      GacoCms.translated_column(t, :key)
      GacoCms.translated_column(t, :title)
      GacoCms.translated_column(t, :summary)
      GacoCms.translated_column(t, :content)
      t.text :template
      t.text :photo_url

      t.timestamps
    end
  end
end
