# frozen_string_literal: true

class CreateCmsFields < ActiveRecord::Migration[7.0]
  def change
    create_table GacoCms::Field.table_name do |t|
      t.string :key
      GacoCms.translated_column(t, :title)
      GacoCms.translated_column(t, :description)
      t.belongs_to :field_group, null: false, foreign_key: { to_table: GacoCms::FieldGroup.table_name }
      t.boolean :repeat, default: false
      t.string :kind, default: 'text_field'
      GacoCms.translated_column(t, :def_value)
      t.boolean :required, default: false
      t.boolean :translatable, default: false
      t.integer :position, default: 0
      GacoCms.translated_column(t, :data)

      t.timestamps
    end
  end
end
