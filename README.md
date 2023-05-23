# GacoCms
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "gaco_cms"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install gaco_cms
rails railties:install:migrations
```
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


## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Development
### Build assets
```bash
    yarn build && yarn build:css && yarn build:css_front
    # TODO: copy static assets into vendor/fontawesome and vendor/tinymce
```

## TODOs
- Migration create default active theme
- Instead of themes, use themes, use sites (1 site by default)
- Migration create default page_type :pages, :posts, and sample page + sample post
- key make single varchar instead of jsonb
- Move default data created by migration to rake task:initial_data or initializer