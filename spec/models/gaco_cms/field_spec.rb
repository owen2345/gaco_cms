# frozen_string_literal: true

require 'rails_helper'
describe GacoCms::Field, type: :model do
  let(:group) { create(:field_group) }

  it 'creates successfully the model' do
    expect { create(:field) }.to change(described_class, :count)
  end

  it 'supports translated title' do
    model = build(:field)
    expect(model.title_data).to be_a(Hash)
  end

  describe 'when validating' do
    it 'validates uniqueness of key for each group' do
      _field1 = create(:field, field_group: group, key: 'my_key')
      field2 = build(:field, field_group: group, key: 'my_key').tap(&:validate)
      expect(field2.errors.key?(:key)).to be_truthy
    end
  end

  describe 'scopes' do
    describe '#ordered' do
      it 'returns ordered groups by position attribute' do
        f2 = create(:field, position: 2, field_group: group)
        f1 = create(:field, position: 1, field_group: group)
        expect(group.fields.ordered).to eq([f1, f2])
      end
    end
  end

  describe '.dropdown_data' do
    it 'returns the list of available field kinds' do
      res = described_class.dropdown_data.map(&:last)
      expect(res).to match(array_including(described_class::KINDS))
    end

    it 'includes extra kinds defined in cms settings' do
      extra_fields = { color: { label: { en: 'Color en', de: 'Color de' } } }
      kinds = described_class::KINDS + [:color]
      stub_const("#{described_class.name}::EXTRA_KINDS", extra_fields)
      stub_const("#{described_class.name}::KINDS", kinds.concat([:color]))
      expect(described_class.dropdown_data).to include(['Color en', :color])
    end
  end

  describe '#default_value_tpl' do
    it 'returns cms template for page field' do
      field = build(:field, :page)
      expect(field.default_value_tpl).to include('fields/default_value/page')
    end

    it 'returns extra_field template if defined' do
      extra_fields = { color: { default_value_tpl: 'my_template' } }
      stub_const("#{described_class.name}::EXTRA_KINDS", extra_fields)
      field = build(:field, kind: :color)
      expect(field.default_value_tpl).to eq(extra_fields[:color][:default_value_tpl])
    end
  end

  describe '#allow_translation?' do
    it 'returns false for page field' do
      expect(build(:field, :page).allow_translation?).to be_falsey
    end

    it 'returns true for other known field' do
      expect(build(:field, :text_field).allow_translation?).to be_truthy
    end

    it 'returns true if extra_field defined it' do
      extra_fields = { color: { translatable: true } }
      stub_const("#{described_class.name}::EXTRA_KINDS", extra_fields)
      expect(build(:field, kind: :color).allow_translation?).to be_truthy
    end
  end

  describe '#tpl' do
    it 'returns the template used to fill field values' do
      expect(build(:field, :text_field).tpl).to include('admin/fields/render/text_field')
    end

    it 'returns the template configured to fill field values for the extra_field' do
      extra_fields = { color: { tpl: 'my_template' } }
      stub_const("#{described_class.name}::EXTRA_KINDS", extra_fields)
      expect(build(:field, kind: :color).tpl).to include(extra_fields[:color][:tpl])
    end
  end

  describe 'callbacks' do
    describe 'when updated key' do
      it 'updates field_key on all dependant field values' do
        new_key = 'new_key'
        value = create(:field_value)
        value.field.update!(key: new_key)
        expect(value.reload.field_key).to eq(new_key)
      end
    end
  end
end
