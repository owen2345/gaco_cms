# frozen_string_literal: true

require 'rails_helper'
describe GacoCms::ShortcodeParser, type: :service do
  describe 'when parsing page content' do
    let!(:page) { create(:page) }
    let(:page2) { create(:page) }

    describe '#page_content' do
      it 'replaces with the page content' do
        res = described_class.call('this is [page_content]', page)
        expect(res).to eq("this is #{page.content}")
      end

      it 'replaces with the page content from specified page' do
        res = described_class.call("this is [page_content page_id=#{page2.id}]", page)
        expect(res).to eq("this is #{page2.content}")
      end

      it 'replaces with the page content from specified page by key' do
        res = described_class.call("this is [page_content page_key=#{page2.key}]", page)
        expect(res).to eq("this is #{page2.content}")
      end

      it 'returns all nested shortcodes parsed' do
        create(:field_value, record: page, field_key: :photo, value: '[page_photo]')
        page.update!(content: 'This is the photo: [page_field key=photo]')
        res = described_class.call('[page_content]', page)
        expect(res).to include("This is the photo: <img src='#{page.photo_url}'")
      end

      it 'replaces with "PageNotFound" if the specified page does not exist' do
        res = described_class.call('this is [page_content page_id=100]', page)
        expect(res).to include('--PageNotFound--')
      end
    end

    describe '#page_title' do
      it 'replaces with the page title' do
        res = described_class.call('this is [page_title]', page)
        expect(res).to eq("this is #{page.title}")
      end

      it 'replaces with the page title from specified page' do
        res = described_class.call("this is [page_title page_id=#{page2.id}]", page)
        expect(res).to eq("this is #{page2.title}")
      end

      it 'replaces with the page title from specified page by key' do
        res = described_class.call("this is [page_title page_key=#{page2.key}]", page)
        expect(res).to eq("this is #{page2.title}")
      end
    end

    describe '#page_photo' do
      it 'replaces with the page photo tag' do
        res = described_class.call('this is [page_photo]', page)
        expect(res).to include("src='#{page.photo_url}'")
      end

      it 'replaces with the page photo tag from specified page' do
        res = described_class.call("this is [page_photo page_id=#{page2.id}]", page)
        expect(res).to include("src='#{page2.photo_url}'")
      end

      it 'replaces with the page photo tag from specified page by key' do
        res = described_class.call("this is [page_photo page_key=#{page2.key}]", page)
        expect(res).to include("src='#{page2.photo_url}'")
      end
    end

    describe '#page_field' do
      it 'replaces with the page field value' do
        create(:field_value, field_key: :name, record: page)
        res = described_class.call('this is [page_field key=name]', page)
        expect(res).to eq("this is #{page.the_value(:name)}")
      end

      it 'replaces with the page field value from specified page' do
        create(:field_value, field_key: :name, record: page2)
        res = described_class.call("this is [page_field key=name page_id=#{page2.id}]", page)
        expect(res).to eq("this is #{page2.the_value(:name)}")
      end
    end

    describe '#page_img_field' do
      it 'replaces with the page field value' do
        create(:field_value, field_key: :photo, record: page)
        res = described_class.call('this is [page_img_field key=photo]', page)
        expect(res).to include("src='#{page.the_value(:photo)}'")
      end

      it 'replaces with the page field value from specified page' do
        create(:field_value, field_key: :photo, record: page2)
        res = described_class.call("this is [page_img_field key=photo page_id=#{page2.id}]", page)
        expect(res).to include("src='#{page2.the_value(:photo)}'")
      end
    end

    describe '#page_field_multiple' do
      it 'replaces with the page field values' do
        tpl = '[page_field_multiple key="photo" content="<li>{field_yield}</li>" wrapper="<ul>{yield}</ul>"]'
        values = create_list(:field_value, 2, field_key: :photo, record: page)
        res = described_class.call(tpl, page)
        values.each { |val| expect(res).to include("<li>#{val.value}</li>") }
        expect(res).to include('<ul><li>')
      end

      it 'replaces with the page field values from specified page' do
        tpl = "[page_field_multiple key='photo' page_id=#{page2.id} content='<li>{field_yield}</li>' wrapper='<ul>{yield}</ul>']"
        values = create_list(:field_value, 2, field_key: :photo, record: page2)
        res = described_class.call(tpl, page)
        values.each { |val| expect(res).to include("<li>#{val.value}</li>") }
        expect(res).to include('<ul><li>')
      end
    end

    describe '#page_grouped_fields' do
      let!(:name1) { create(:field_value, field_key: :name, record: page, group_no: 1) }
      let!(:name2) { create(:field_value, field_key: :name, record: page, group_no: 2) }
      let!(:photo1) { create(:field_value, field_key: :photo, record: page, group_no: 1) }
      let!(:photo2) { create(:field_value, field_key: :photo, record: page, group_no: 2) }
      let(:tpl) { '[page_grouped_fields keys="name,photo" wrapper="<ul>{yield}</ul>" content="<li>{name_yield}: {photo_yield}</li>"]' }

      it 'replaces with the page grouped-field values' do
        res = described_class.call(tpl, page)
        expect(res).to include("<li>#{name1.value}: #{photo1.value}</li>")
        expect(res).to include("<li>#{name2.value}: #{photo2.value}</li>")
      end

      it 'replaces with the page grouped-field values inside the defined wrapper' do
        res = described_class.call(tpl, page)
        expect(res).to include('<ul><li>')
      end

      it 'replaces with the page grouped-field values from specified page' do
        tpl = "[page_grouped_fields keys='name,photo' page_id=#{page.id} wrapper='<ul>{yield}</ul>' content='<li>{name_yield}: {photo_yield}</li>']"
        res = described_class.call(tpl, page2)
        expect(res).to include("<li>#{name1.value}: #{photo1.value}</li>")
        expect(res).to include("<li>#{name2.value}: #{photo2.value}</li>")
      end
    end

    describe '#page_url' do
      it 'replaces with the page url' do
        res = described_class.call('this is [page_url]', page)
        expect(res).to eq("this is #{GacoCms::ApplicationHelper.page_url_for(page.id)}")
      end

      it 'replaces with the page url from specified page' do
        res = described_class.call("this is [page_url page_id=#{page2.id}]", page)
        expect(res).to eq("this is #{GacoCms::ApplicationHelper.page_url_for(page2.id)}")
      end

      it 'replaces with the page url from specified page by key' do
        res = described_class.call("this is [page_url page_key=#{page2.key}]", page)
        expect(res).to eq("this is #{GacoCms::ApplicationHelper.page_url_for(page2.id)}")
      end
    end
  end

  describe 'when themes' do
    let(:theme) { create(:theme) }

    describe '#theme_field' do
      it 'replaces with the page url' do
        create(:field_value, record: theme, field_key: :name)
        res = described_class.call('this is [theme_field key=name]', theme)
        expect(res).to eq("this is #{theme.the_value(:name)}")
      end
    end

    describe '#theme_img_field' do
      it 'replaces with the page url' do
        create(:field_value, record: theme, field_key: :photo)
        res = described_class.call('this is [theme_img_field key=photo style="width: 100%"]', theme)
        expect(res).to include("src='#{theme.the_value(:photo)}' style=\"width")
      end
    end
  end
end
