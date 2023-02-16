# frozen_string_literal: true

require 'rails_helper'
describe GacoCms::PageType, type: :model do
  let(:ptype) { create(:page_type) }

  it 'creates successfully the model' do
    expect { ptype }.to change(described_class, :count)
  end

  it 'supports translated title' do
    model = build(:field_group)
    expect(model.title_data).to be_a(Hash)
  end

  it 'has many #field_groups' do
    group = create(:field_group, record: ptype)
    expect(ptype.field_groups).to include(group)
  end

  describe 'scopes' do
    describe '.title_ordered' do
      it 'orders the pages per title' do
        ptype1 = create(:page_type, title: 'Last')
        ptype2 = create(:page_type, title: 'First')
        expect(described_class.title_ordered).to eq([ptype2, ptype1])
      end
    end
  end

  describe 'callbacks' do
    describe 'when updated' do
      it 'touches the pages to update the updated_at attributes used for caching' do
        page_previous_date = 5.days.ago
        page = create(:page, page_type: ptype, updated_at: page_previous_date)
        ptype.update!(title: 'New title')
        expect(page.reload.updated_at).not_to eq(page_previous_date)
      end
    end
  end
end
