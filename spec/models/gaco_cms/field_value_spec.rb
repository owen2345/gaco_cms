# frozen_string_literal: true

require 'rails_helper'
describe GacoCms::FieldValue, type: :model do
  let(:field) { create(:field) }

  it 'creates successfully the model' do
    expect { create(:field_value) }.to change(described_class, :count)
  end

  it 'supports translated title' do
    model = build(:field_value)
    expect(model.value_data).to be_a(Hash)
  end

  describe 'scopes' do
    describe '.group_nos_for' do
      it 'returns all the detected group numbers for the given group (ordered)' do
        _v1 = create(:field_value, field: field, group_no: 2)
        _v2 = create(:field_value, field: field, group_no: 1)
        _v3 = create(:field_value, field: field, group_no: 3)
        expect(described_class.group_nos_for(field.field_group)).to eq([1, 2, 3])
      end
    end

    describe '.all_or_new_for' do
      it 'returns all existent field values for the given field in a given group' do
        v1 = create(:field_value, field: field, group_no: 2)
        _v2 = create(:field_value, field: field, group_no: 1)
        res = described_class.all_or_new_for(field, 2)
        expect(res.to_a).to eq([v1])
      end

      it 'returns a new field-value if no values yet for the given field in a given group' do
        res = described_class.all_or_new_for(field, 2)
        expect(res.map(&:new_record?)).to eq([true])
      end
    end

    describe '.grouped' do
      it 'returns values grouped per group_no (group_no and position ordered ascendant)' do
        v10 = create(:field_value, field: field, group_no: 2, position: 1)
        v11 = create(:field_value, field: field, group_no: 2, position: 1)
        v20 = create(:field_value, field: field, group_no: 1, position: 1)
        v21 = create(:field_value, field: field, group_no: 1, position: 1)
        expect(described_class.grouped).to match([[v20, v21], [v10, v11]])
      end
    end

    describe '.for_group' do
      it 'returns the values that belongs to the given group' do
        field2 = create(:field, field_group: field.field_group)
        v1 = create(:field_value, field: field)
        v2 = create(:field_value, field: field2)
        _field_from_another_group = create(:field_value)
        expect(described_class.for_group(field.field_group)).to match_array([v1, v2])
      end
    end

    describe '.ordered' do
      it 'returns ordered values (ascendant)' do
        v1 = create(:field_value, field: field, position: 2)
        v2 = create(:field_value, field: field, position: 1)
        expect(described_class.ordered).to eq([v2, v1])
      end
    end
  end

  describe '#the_value' do
    it 'returns shortcode evaluated value' do
      page2 = create(:page, content: 'Sample content')
      value = create(:field_value, value: "This is page 2: [page_content page_id=#{page2.id}]")
      expect(value.the_value).to eq("This is page 2: #{page2.content}")
    end
  end

  describe '#value_for_input' do
    describe 'when new record' do
      it 'returns default value if not translatable' do
        field.def_value = 'Sample Value'
        allow(field).to receive(:translatable).and_return(false)
        value = build(:field_value, field: field)
        expect(value.value_for_input).to eq(value.def_value)
      end

      it 'returns default value as json format if field is translatable' do
        field.def_value = { en: 'EnVal', de: 'DeVal' }
        allow(field).to receive(:translatable).and_return(true)
        value = build(:field_value, field: field)
        expect(value.value_for_input).to eq(value.def_value_data.to_json)
      end
    end

    describe 'when not a new record' do
      it 'returns saved value if not translatable' do
        value = create(:field_value, field: field)
        allow(field).to receive(:translatable).and_return(false)
        expect(value.value_for_input).to eq(value.value)
      end

      it 'returns saved value as json format if field is translatable' do
        value = create(:field_value, field: field)
        allow(field).to receive(:translatable).and_return(true)
        expect(value.value_for_input).to eq(value.value_data.to_json)
      end
    end
  end

  describe 'callbacks' do
    describe 'when creating' do
      it 'retrieves the field_key from the field' do
        value = build(:field_value, field: field).tap(&:validate)
        expect(value.field_key).to eq(field.key)
      end
    end
  end
end
