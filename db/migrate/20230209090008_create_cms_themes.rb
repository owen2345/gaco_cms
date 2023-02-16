# frozen_string_literal: true

class CreateCmsThemes < ActiveRecord::Migration[7.0]
  def change
    create_table GacoCms::Theme.table_name do |t|
      t.string :title, null: false
      t.string :key, null: false, unique: true
      t.boolean :active, default: false

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        GacoCms::Theme.create!(title: 'Default Theme', key: 'default', active: true)
      end
    end
  end
end
