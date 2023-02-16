# frozen_string_literal: true

require 'rails_helper'
describe GacoCms::FieldGroup, type: :model do
  it 'creates successfully the model' do
    expect { create(:field_group) }.to change(described_class, :count)
  end

  it 'supports translated title' do
    model = build(:field_group)
    expect(model.title_data).to be_a(Hash)
  end

  describe 'scopes' do
    describe '#ordered' do
      it 'returns ordered groups by position attribute' do
        g2 = create(:field_group, position: 2)
        g1 = create(:field_group, position: 1)
        expect(described_class.ordered).to eq([g1, g2])
      end
    end
  end

  describe '#available_records' do
    let(:res) { build(:field_group).available_records }

    it 'includes the page_types list' do
      ptype = create(:page_type)
      expect(res.values.second).to include([ptype.title, "#{ptype.class.name}/#{ptype.id}"])
    end

    it 'includes the pages list' do
      page = create(:page)
      expect(res.values.first).to include([page.title, "#{page.class.name}/#{page.id}"])
    end

    it 'includes the themes list' do
      theme = create(:theme)
      expect(res.values.third).to include([theme.title, "#{theme.class.name}/#{theme.id}"])
    end
  end

  describe '#record_label' do
    it 'returns a label for page_types' do
      ptype = create(:page_type)
      group = create(:field_group, record: ptype)
      expect(group.record_label).to include("All pages under \"#{ptype.title}\"")
    end

    it 'returns a label for non page_types' do
      page = create(:page)
      group = create(:field_group, record: page)
      expect(group.record_label).to include("#{page.class.human_name} => \"#{page.title}\"")
    end
  end
end
