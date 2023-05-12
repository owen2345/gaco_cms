# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_02_16_220457) do
  create_table "simple_cms_draft_records", force: :cascade do |t|
    t.string "record_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simple_cms_field_groups", force: :cascade do |t|
    t.string "key"
    t.text "title"
    t.text "description"
    t.string "record_type"
    t.integer "record_id"
    t.boolean "repeat", default: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_simple_cms_field_groups_on_record"
  end

  create_table "simple_cms_field_values", force: :cascade do |t|
    t.integer "field_id", null: false
    t.string "field_key"
    t.text "value"
    t.integer "group_no", default: 0
    t.integer "position", default: 0
    t.string "record_type"
    t.integer "record_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_simple_cms_field_values_on_field_id"
    t.index ["record_type", "record_id"], name: "index_simple_cms_field_values_on_record"
  end

  create_table "simple_cms_fields", force: :cascade do |t|
    t.string "key"
    t.text "title"
    t.text "description"
    t.integer "field_group_id", null: false
    t.boolean "repeat", default: false
    t.string "kind", default: "text_field"
    t.text "def_value"
    t.boolean "required", default: false
    t.boolean "translatable", default: false
    t.integer "position", default: 0
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_group_id"], name: "index_simple_cms_fields_on_field_group_id"
  end

  create_table "simple_cms_media_files", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simple_cms_page_types", force: :cascade do |t|
    t.string "key"
    t.text "title"
    t.text "template", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_simple_cms_page_types_on_key"
  end

  create_table "simple_cms_pages", force: :cascade do |t|
    t.text "key"
    t.text "title"
    t.text "summary"
    t.text "content"
    t.text "template"
    t.text "photo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "page_type_id", null: false
    t.index ["page_type_id"], name: "index_simple_cms_pages_on_page_type_id"
  end

  create_table "simple_cms_themes", force: :cascade do |t|
    t.string "title", null: false
    t.string "key", null: false
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "simple_cms_field_values", "simple_cms_fields", column: "field_id"
  add_foreign_key "simple_cms_fields", "simple_cms_field_groups", column: "field_group_id"
  add_foreign_key "simple_cms_pages", "simple_cms_page_types", column: "page_type_id"
end
