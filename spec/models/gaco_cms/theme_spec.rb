# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_field_values_owner_spec'
describe GacoCms::Theme, type: :model do
  let(:theme) { create(:theme) }

  it 'creates successfully the model' do
    expect { theme }.to change(described_class, :count)
  end

  describe 'field_values helper methods' do
    it_behaves_like 'field_values_owner', :theme
  end
end
