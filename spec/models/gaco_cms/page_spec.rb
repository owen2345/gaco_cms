# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_field_values_owner_spec'
describe GacoCms::Page, type: :model do
  let(:page) { create(:page) }

  it 'creates successfully the model' do
    expect { page }.to change(described_class, :count)
  end

  it 'supports translated title' do
    model = build(:page)
    expect(model.title_data).to be_a(Hash)
  end

  describe 'field_values helper methods' do
    it_behaves_like 'field_values_owner', :page
  end

  describe '#all_field_groups' do
    let!(:parent_group) { create(:field_group, record: page.page_type) }
    let!(:page_group) { create(:field_group, record: page) }

    it 'includes the field_groups from parent PageType' do
      expect(page.all_field_groups).to include(parent_group)
    end

    it 'includes the field_groups from current page' do
      expect(page.all_field_groups).to include(page_group)
    end
  end

  describe '#the_content' do
    it 'returns the page content inside the template' do
      expect(page.the_content).to include(page.content)
    end

    it 'replaces only the content shortcode from the template' do
      page.template = 'Sample template with [page_content]'
      expect(page.the_content).to eq("Sample template with #{page.content}")
    end

    it 'prepends the page content if template does not include the content shortcode' do
      page.template = 'Sample template without content shortcode'
      expect(page.the_content).to eq("#{page.content}#{page.template}")
    end

    it 'uses page_type\'s template if page\'s template is empty' do
      page.template = ''
      page.page_type.template = 'Sample page_type template and [page_content]'
      expect(page.the_content).to eq("Sample page_type template and #{page.content}")
    end
  end
end
