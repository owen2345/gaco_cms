# frozen_string_literal: true

class CreateCmsFieldValues < ActiveRecord::Migration[7.0]
  def change
    create_table GacoCms::FieldValue.table_name do |t|
      t.belongs_to :field, null: false, foreign_key: { to_table: GacoCms::Field.table_name }
      t.string :field_key
      GacoCms.translated_column(t, :value)
      t.integer :group_no, default: 0
      t.integer :position, default: 0
      t.references :record, polymorphic: true

      t.timestamps
    end
  end
end
