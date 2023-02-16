# frozen_string_literal: true

shared_examples_for 'field_values_owner' do |owner_key|
  let(:owner) { create(owner_key) }

  describe 'values helpers' do
    let(:field_group) { create(:field_group, :with_fields, record: owner, qty_fields: 1) }
    let(:field) { field_group.fields.first }
    let(:field2) { create(:field, field_group: field_group) }
    let(:value_data) { { en: 'en value', es: 'es value' } }

    describe '#the_value' do
      let!(:value) { create(:field_value, record: owner, field: field, value: value_data) }

      it 'returns the field value for the given key and the current locale' do
        expect(owner.the_value(field.key)).to eq(value_data[:en])
      end

      it 'caches the result for the next time' do
        expect(Rails.cache).to receive(:fetch).with(include(field.key), any_args)
        owner.the_value(field.key)
      end

      it 'does not cache the result if specified' do
        expect(Rails.cache).not_to receive(:fetch)
        owner.the_value(field.key, cache: false)
      end
    end

    describe '#the_values' do
      let!(:values) { create_list(:field_value, 2, record: owner, field: field, value: value_data) }

      it 'returns all the possible ordered values' do
        expect(owner.the_values(field.key)).to eq([value_data[:en], value_data[:en]])
      end
    end

    describe '#the_grouped_values' do
      let!(:value_g1) { create(:field_value, record: owner, field: field, value: value_data, group_no: 0) }
      let!(:value_g2) { create(:field_value, record: owner, field: field, value: value_data, group_no: 1) }

      it 'returns all values correctly grouped' do
        res = owner.the_grouped_values(field.key)
        expect(res).to match_array([hash_including(field.key), hash_including(field.key)])
      end

      describe 'when multiple fields' do
        let!(:value1_g1) { create(:field_value, record: owner, field: field2, value: value_data, group_no: 0) }
        let!(:value2_g2) { create(:field_value, record: owner, field: field2, value: value_data, group_no: 1) }

        it 'returns the values all the provided attributes' do
          res = owner.the_grouped_values(field.key, field2.key)
          expect(res).to match_array([hash_including(field.key, field2.key), hash_including(field.key, field2.key)])
        end
      end
    end
  end

  describe 'associations' do
    it 'has many #field_groups' do
      group = create(:field_group, record: owner)
      expect(owner.field_groups).to include(group)
    end

    it 'has many #fields' do
      create(:field_group, :with_fields, qty_fields: 1, record: owner)
      expect(owner.fields).to be_any
    end

    it 'has many #field_values' do
      group = create(:field_group, :with_fields, qty_fields: 1, record: owner)
      create(:field_value, record: owner, field: group.fields.first)
      expect(owner.field_values).to be_any
    end
  end
end
