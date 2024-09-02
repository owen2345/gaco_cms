# GacoCms
GacoCMS is a simple CMS for Rails application. It allows you to create pages with custom fields and themes. It is a vanilla CMS with no other dependencies except `Rails` and `liquid`. 

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'gaco_cms', github: 'owen2345/gaco_cms'
```

And then execute:
```bash
$ bundle install
$ rails db:migrate
```
Generate config file and basic templates
```bash
$ rails g gaco_cms:install
```
Check the `config/initilizers/gaco_cms.rb` file to customize the settings, like the controller to manage authentication, the default theme, etc.

Add `//= link gaco_cms` in app/assets/config/manifest.js

## Extra fields
```ruby
color_settings = {
  tpl: 'my_fields/color',
  default_value_tpl: 'my_fields/color_default_value',
  translatable: false,
  label: { en: 'Color' }
}
GacoCms::Config.add_extra_field(:color, color_settings)
```

## Sample cms settings
```ruby
GacoCms::Config.parent_front_controller = 'ApplicationController'
GacoCms::Config.parent_backend_controller = 'Admin::BaseController'
GacoCms::Config.front_layout = ->(_controller) { 'application' }
```

## Shorcodes
- page_content
- page_title
- page_photo
- page_field
- page_field_tpl
- page_img_field
- page_field_multiple
- page_grouped_fields

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Development
### Build assets
This gem is published with precompiled assets to reduce dependencies and conflicts with the host application. So, every time you make changes to the assets, you need to recompile them and commit to the repository.
```bash
    docker-compose run test bash
    yarn build && yarn build:css && yarn build:css_front
```
Commit the changes to the repository

## TODOs
- add github action to do pre-compilation automatically
- copy static assets into vendor/fontawesome and vendor/tinymce
- Migration create default active theme
- Instead of themes, use themes, use sites (1 site by default)
- Migration create default page_type :pages, :posts, and sample page + sample post
- key make single varchar instead of jsonb
- Move default data created by migration to rake task:initial_data or initializer
- Once saved a page content, restore iframe scroll to previous position
- Add button "Open page" when page form
- Make page content field larger
- Add components instead of group fields
