# frozen_string_literal: true

module GacoCms
  class ThemeContentGenerator
    def call
      generate_pages
      generate_theme_settings
    end

    private

    def generate_pages
      Page.create(title: 'Home', key: :home, content: home_content)
      # TODO: create content for below pages
      Page.create(title: 'Shortcodes', key: :shortcodes, content: gallery_content)
      Page.create(title: 'Custom Fields', key: :custom_fields, content: gallery_content)
      Page.create(title: 'Gallery', key: :gallery, content: gallery_content)
    end

    def generate_theme_settings
      theme = Theme.current
      group = theme.field_groups.create!(title: 'Menus', repeat: true)
      label_field = group.fields.create!(title: 'Label', key: :menu_label, kind: :text_field, translatable: true, required: true)
      url_field = group.fields.create!(title: 'Url', key: :menu_url, kind: :text_field, required: true)

      theme.field_values.create!(value: 'Home', group_no: 1, field: label_field)
      theme.field_values.create!(value: '/', group_no: 1, field: url_field)

      theme.field_values.create!(value: 'Gallery', group_no: 2, field: label_field)
      theme.field_values.create!(value: '[page_url key=gallery]', group_no: 2, field: url_field)
    end

    def home_content
      '''
        GacoCms is a lightweight CMS built in RubyonRails, to be included in any Rails application as the main purpose in mind.
        <br>
        Most outstanding characteristics are:
        <ul>
          <li>No extra Ruby dependencies required, except <a href="https://github.com/owen2345/buddy_translatable" target="_blank">translatable</a> that can conflict with existent applications</li>
          <li>Surpricingly fast</li>
          <li>Support multilanguage</li>
          <li>Manage your content structure via custom fields</li>
          <li>Manage content easily via shortcodes</li>
        </ul>
        <div class="alert alert-info">Note: Any error, issue, improvement, please let us know in https://github.com/owen2345/gaco_cms</div>
      '''
    end

    def gallery_content
      '''
        This is a sample gallery page
      '''
    end
  end
end
