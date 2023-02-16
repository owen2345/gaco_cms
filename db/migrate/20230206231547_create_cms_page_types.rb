# frozen_string_literal: true

class CreateCmsPageTypes < ActiveRecord::Migration[7.0]
  def change
    create_table GacoCms::PageType.table_name do |t|
      t.string :key, index: true, unique: true
      GacoCms.translated_column(t, :title)
      t.text :template, default: ''

      t.timestamps
    end

    change_table GacoCms::Page.table_name do |t|
      t.belongs_to :page_type, null: false, foreign_key: { to_table: GacoCms::PageType.table_name }
    end

    reversible do |dir|
      dir.up do
        GacoCms::PageType.create!(title: 'Pages', key: 'pages')
      end
    end
  end
end
