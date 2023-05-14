# frozen_string_literal: true

class CreateCmsDefaultData < ActiveRecord::Migration[7.0]
  def up
    _theme = GacoCms::Theme.create(key: :default, title: 'Default theme', active: true)
    page_type = GacoCms::PageType.create(key: :pages, title: 'Pages')
    page_type.pages.create(title: 'Sample Page', key: :sample1, content: 'This is a sample page')
    post_type = GacoCms::PageType.create(key: :posts, title: 'Posts')
    post_type.pages.create(title: 'Sample Page', key: :sample1, content: 'This is a sample page')
  end

  def down
    GacoCms::PageType.where(key: :pages).destroy_all
    GacoCms::PageType.where(key: :posts).destroy_all
    GacoCms::Theme.where(key: :default).destroy_all
  end
end
