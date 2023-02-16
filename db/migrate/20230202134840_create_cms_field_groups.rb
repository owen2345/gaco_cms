# frozen_string_literal: true

class CreateCmsFieldGroups < ActiveRecord::Migration[7.0]
  def change
    create_table GacoCms::FieldGroup.table_name do |t|
      t.string :key
      GacoCms.translated_column(t, :title)
      GacoCms.translated_column(t, :description)
      t.references :record, polymorphic: true
      t.boolean :repeat, default: false
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
