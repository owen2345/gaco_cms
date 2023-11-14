# frozen_string_literal: true

require 'liquid'
module GacoCms
  class ShortcodeParser < ApplicationService # rubocop:disable Metrics/ClassLength
    attr_reader :content, :record, :ignored_shortcodes

    def initialize(content, record, ignore: [])
      @content = content
      @record = record
      @ignored_shortcodes = Array(ignore)
      super
    end

    def call
      counter = 0
      loop do
        detected = @content.to_s.scan(/#{shortcodes_regex}/).to_a
        break if detected.empty?
        break log("Too many levels detected, skipping after #{counter} levels", mode: :error) if counter > 5

        detected.each { |item| @content = replace_shortcode(item) }
        counter += 1
      end
      @content
    end

    private

    def shortcodes # rubocop:disable Metrics/MethodLength
      pp_sample = '<img src="[page_field key=\'photo\']"/> Or [page_field key=\'photo\' page_id=10 group_no=1]'
      pif_sample = '[page_img_field key="photo"] Or [page_img_field key="photo" page_id=10 style="width: 100%"]'
      pmf_sample = '[page_field_multiple key="thumbnail" content="<li><img src=\'{field_yield}\' /></li>" '\
                    'wrapper="<ul>{yield}</ul>"] Or [page_field_multiple key="thumbnail" page_id=10 content=...'
      pgf_sample = '[page_grouped_fields keys="name,photo" wrapper="<ul>{yield}</ul>" content="<li>{name_yield}: '\
                   '{photo_yield}</li>"] Or [page_grouped_fields keys="name,photo" page_id=10 content=...'
      tf_sample = '<img src="[theme_field key=\'photo\'] or [theme_field key=\'photo\' group_no=1]" />'
      pf_sample = '[page_photo] or [page_photo page_id=10 style=".."]'
      pftpl_sample = '[page_field_tpl key=\'photos\']'
      pgftpl_sample = '[page_field_group_tpl key=\'photos\']'
      pg_sample = '[page_group key="my_key"] or [page_group key="my_key" page_id=10 wrapper="<div class=\'row\'>{yield}</div>"]'
      {
        page_content: { render: method(:page_content_parser), sample: '[page_content] or [page_content page_id=10]' },
        page_title: { render: method(:page_title_parser), sample: '[page_title] or [page_title page_id=10]' },
        page_photo: { render: method(:page_photo_parser), sample: pp_sample },
        page_field: { render: method(:page_field_parser), sample: pf_sample },
        page_field_tpl: { render: method(:page_field_tpl_parser), sample: pftpl_sample },
        page_field_group_tpl: { render: method(:page_fgroup_tpl_parser), sample: pgftpl_sample },
        page_img_field: { render: method(:page_img_field_parser), sample: pif_sample },
        page_field_multiple: { render: method(:page_field_multiple_parser), sample: pmf_sample },
        # page_fields: { render: method(:page_fields_parser), sample:  },
        page_grouped_fields: { render: method(:page_grouped_fields_parser), sample: pgf_sample },
        page_url: { render: method(:page_url_parser), sample: '[page_url] or [page_url page_id=10]' },
        page_group: { render: method(:page_group_parser), sample: pg_sample },
        theme_field: { render: method(:theme_field_parser), sample: tf_sample },
        theme_img_field: { render: method(:theme_img_field_parser), sample: '[theme_img_field key="my_img"]' }
      }.except(*ignored_shortcodes)
    end

    def shortcodes_regex
      "(\\[(#{shortcodes.keys.join('|')})((\s|%)((?!\\]).)*|)\\])"
    end

    # @param item [Array[shortcode, code, attrs]]
    def replace_shortcode(item)
      shortcode, code, attrs = item
      attrs = parse_shortcode_attrs(attrs)
      shortcode, shortcode_content = shortcode_content_for(shortcode, code)
      args = { shortcode: shortcode, code: code, shortcode_content: shortcode_content }
      content.sub(shortcode, parse_shortcode(code, attrs, args).to_s)
    end

    def shortcode_content_for(shortcode, code)
      close_code = "[/#{code}]"
      return [shortcode, nil] unless content.include?(close_code)

      shortcode_bk = shortcode
      tmp_content = content[content.index(shortcode)..]
      shortcode = tmp_content[0..(tmp_content.index(close_code) + close_code.size - 1)]
      [shortcode, shortcode.sub(shortcode_bk, '').sub(close_code, '')]
    end

    # determine the content to replace instead the shortcode
    def parse_shortcode(code, attrs, args = {})
      renderer = shortcodes[code.to_sym][:render]
      if renderer.is_a?(String)
        params = { attributes: attrs, args: args }
        ActionController::Base.new.render_to_string template: renderer, locals: params, formats: [:html]
      else
        shortcodes[code.to_sym][:render].call(attrs, args)
      end
    end

    # parse the attributes of a shortcode
    def parse_shortcode_attrs(text)
      return {} if text.blank?

      res = {}
      regex = /(\w+)\s*=\s*"([^"]*)"(?:\s|$)|(\w+)\s*=\s*\'([^\']*)\'(?:\s|$)|(\w+)\s*=\s*([^\s\'"]+)(?:\s|$)|"([^"]*)"(?:\s|$)|(\S+)(?:\s|$)/ # rubocop:disable Style/RedundantRegexpEscape, Layout/LineLength
      text.scan(regex).each do |item|
        item.each_with_index do |c, index|
          break res[c] = item[index + 1] if c.present?
        end
      end
      res
    end

    def img_tag_for(url, attrs)
      attrs = attrs.slice('style', 'alt')
      props = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
      "<img src='#{url}' #{props} />"
    end

    def replace_field_wrapper(attrs, content)
      return content unless attrs.key?('wrapper')

      attrs['wrapper'].to_s.sub('{yield}', content).gsub('&lt;', '<').gsub('&gt;', '>')
    end

    ############################
    def calc_context(context, attrs, klass: Page)
      return context if context
      return Page.where_key_with(attrs['page_key']).take if attrs['page_key'].present?

      attrs['page_id'].present? ? klass.find_by(id: attrs['page_id']) : record
    end

    def page_field_parser(attrs, _args, context = nil)
      context = calc_context(context, attrs)
      return '--PageNotFound--' unless context

      context.the_value(attrs['key'])
    end

    def page_field_tpl_parser(attrs, _args, context = nil)
      context = calc_context(context, attrs)
      return '--PageNotFound--' unless context

      field = context.fields.find_by(key: attrs['key'])
      return '--FieldKey not found--' unless field

      data = {} # TODO: add multiple groups support
      data[:values] = context.the_values(field.key) if field.repeat
      data[:value] = context.the_value(field.key) unless field.repeat
      template = Liquid::Template.parse(field.template)
      template.render(**data.stringify_keys)
    end

    def page_fgroup_tpl_parser(attrs, _args, context = nil)
      context = calc_context(context, attrs)
      return '--PageNotFound--' unless context

      group = context.field_groups.find_by(key: attrs['key'])
      return '--FieldGroupNotFound--' unless group

      data = {}
      data[:values] = context.the_group_values(attrs['key'])
      template = Liquid::Template.parse(group.template)
      template.render(**data.stringify_keys)
    end

    def page_field_multiple_parser(attrs, _args, context = nil)
      context = calc_context(context, attrs)
      return '--PageNotFound--' unless context

      res = context.the_values(attrs['key']).map do |val|
        attrs['content'].to_s.gsub('{field_yield}', val)
      end.join
      replace_field_wrapper(attrs, res)
    end

    def page_img_field_parser(attrs, _args, context = nil)
      context = calc_context(context, attrs)
      return '--PageNotFound--' unless context

      src = context.the_value(attrs['key'])
      img_tag_for(src, attrs)
    end

    def page_grouped_fields_parser(attrs, _args, context = nil)
      context = calc_context(context, attrs)
      return '--PageNotFound--' unless context

      keys = attrs['keys'].to_s.split(',')
      context.the_grouped_values(*keys).map do |fields|
        content = attrs['content'].to_s
        keys.each do |key|
          content = content.gsub("{#{key}_yield}", fields[key])
        end
        replace_field_wrapper(attrs, content)
      end.join
    end

    def page_content_parser(attrs, _args)
      context = calc_context(nil, attrs)
      return '--PageNotFound--' unless context

      context.content
    end

    def page_photo_parser(attrs, _args)
      context = calc_context(nil, attrs)
      return '--PageNotFound--' unless context

      img_tag_for(context.photo_url, attrs)
    end

    def page_title_parser(attrs, _args)
      context = calc_context(nil, attrs)
      return '--PageNotFound--' unless context

      context.title
    end

    def page_url_parser(attrs, _args)
      context = calc_context(nil, attrs)
      return '--PageNotFound--' unless context

      ApplicationHelper.page_url_for(context.key)
    end

    # TODO: add missing test cases
    def page_group_parser(attrs, _args)
      context = calc_context(nil, attrs)
      return '--PageNotFound--' unless context

      group = context.field_groups.find_by(key: attrs['key'])
      return '--GroupNotFound--' unless group

      keys = group.fields.pluck(:key)
      result = context.the_grouped_values(*keys).map do |fields|
        content = group.template.to_s
        keys.each do |key|
          content = content.gsub("{#{key}_yield}", fields[key])
        end
        content
      end.join
      replace_field_wrapper(attrs, result)
    end

    def theme_field_parser(attrs, args)
      page_field_parser(attrs, args, Theme.current)
    end

    def theme_img_field_parser(attrs, args)
      page_img_field_parser(attrs, args, Theme.current)
    end
  end
end

{ "authenticity_token" => "[FILTERED]", "gaco_cms_page" => { "key" => "home", "title" => { "en" => "Home Page", "es" => "Home Page" }, "content" => { "en" => "", "es" => "" }, "template" => "", "summary" => { "en" => "", "es" => "" }, "photo_url" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/vazoq7u7xbc3i0v85qwe8mwtihgv" },
  "field_values_attributes" => {
    "78_25_1_1698255608" => { "id" => "78", "field_id" => "25", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "79_26_1_1698255608" => { "id" => "79", "field_id" => "26", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "137_27_1_1698255608" => { "id" => "137", "field_id" => "27", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "<p>test</p>" } },
    "1_1_1_1698255608" => { "id" => "1", "field_id" => "1", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "58_14_1_1698255608" => { "id" => "58", "field_id" => "14", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "2_2_1_1698255608" => { "id" => "2", "field_id" => "2", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "59_15_1_1698255608" => { "id" => "59", "field_id" => "15", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "3_3_1_1698255608" => { "id" => "3", "field_id" => "3", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "4_4_1_1698255608" => { "id" => "4", "field_id" => "4", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "5_5_1_1698255608" => { "id" => "5", "field_id" => "5", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "48_6_1_1698255608" => { "id" => "48", "field_id" => "6", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/vazoq7u7xbc3i0v85qwe8mwtihgv" }, "49_7_1_1698255608" => { "id" => "49", "field_id" => "7", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => "" }, "64_16_1_1698255608" => { "id" => "64", "field_id" => "16", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "65_17_1_1698255608" => { "id" => "65", "field_id" => "17", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "67_19_1_1698255608" => { "id" => "67", "field_id" => "19", "group_no" => "0", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "57_11_2_1698255608" => { "id" => "57", "field_id" => "11", "group_no" => "1", "position" => "0", "_destroy" => "0", "value" => "fa-home" }, "54_8_2_1698255608" => { "id" => "54", "field_id" => "8", "group_no" => "1", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "55_9_2_1698255608" => { "id" => "55", "field_id" => "9", "group_no" => "1", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "56_10_2_1698255608" => { "id" => "56", "field_id" => "10", "group_no" => "1", "position" => "0", "_destroy" => "0", "value" => "" }, "31_11_2_1698255608" => { "id" => "31", "field_id" => "11", "group_no" => "3", "position" => "0", "_destroy" => "0", "value" => "fa-map-location" }, "7_8_2_1698255608" => { "id" => "7", "field_id" => "8", "group_no" => "3", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "15_9_2_1698255608" => { "id" => "15", "field_id" => "9", "group_no" => "3", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "23_10_2_1698255608" => { "id" => "23", "field_id" => "10", "group_no" => "3", "position" => "0", "_destroy" => "0", "value" => "" }, "32_11_2_1698255608" => { "id" => "32", "field_id" => "11", "group_no" => "4", "position" => "0", "_destroy" => "0", "value" => "fa-calendar-day" }, "8_8_2_1698255608" => { "id" => "8", "field_id" => "8", "group_no" => "4", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "16_9_2_1698255608" => { "id" => "16", "field_id" => "9", "group_no" => "4", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "24_10_2_1698255608" => { "id" => "24", "field_id" => "10", "group_no" => "4", "position" => "0", "_destroy" => "0", "value" => "" }, "33_11_2_1698255608" => { "id" => "33", "field_id" => "11", "group_no" => "5", "position" => "0", "_destroy" => "0", "value" => "fa-star" }, "9_8_2_1698255608" => { "id" => "9", "field_id" => "8", "group_no" => "5", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "17_9_2_1698255608" => { "id" => "17", "field_id" => "9", "group_no" => "5", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "25_10_2_1698255608" => { "id" => "25", "field_id" => "10", "group_no" => "5", "position" => "0", "_destroy" => "0", "value" => "" }, "34_11_2_1698255608" => { "id" => "34", "field_id" => "11", "group_no" => "6", "position" => "0", "_destroy" => "0", "value" => "fa-circle-dollar-to-slot" }, "10_8_2_1698255608" => { "id" => "10", "field_id" => "8", "group_no" => "6", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "18_9_2_1698255608" => { "id" => "18", "field_id" => "9", "group_no" => "6", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "26_10_2_1698255608" => { "id" => "26", "field_id" => "10", "group_no" => "6", "position" => "0", "_destroy" => "0", "value" => "" }, "35_11_2_1698255608" => { "id" => "35", "field_id" => "11", "group_no" => "7", "position" => "0", "_destroy" => "0", "value" => "fa-globe" }, "11_8_2_1698255608" => { "id" => "11", "field_id" => "8", "group_no" => "7", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "19_9_2_1698255608" => { "id" => "19", "field_id" => "9", "group_no" => "7", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "27_10_2_1698255608" => { "id" => "27", "field_id" => "10", "group_no" => "7", "position" => "0", "_destroy" => "0", "value" => "" }, "36_11_2_1698255608" => { "id" => "36", "field_id" => "11", "group_no" => "8", "position" => "0", "_destroy" => "0", "value" => "fa-eye" }, "12_8_2_1698255608" => { "id" => "12", "field_id" => "8", "group_no" => "8", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "20_9_2_1698255609" => { "id" => "20", "field_id" => "9", "group_no" => "8", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } },
    "28_10_2_1698255609" => { "id" => "28", "field_id" => "10", "group_no" => "8", "position" => "0", "_destroy" => "0", "value" => "" }, "37_11_2_1698255609" => { "id" => "37", "field_id" => "11", "group_no" => "9", "position" => "0", "_destroy" => "0", "value" => "fa-bell" }, "13_8_2_1698255609" => { "id" => "13", "field_id" => "8", "group_no" => "9", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "21_9_2_1698255609" => { "id" => "21", "field_id" => "9", "group_no" => "9", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "29_10_2_1698255609" => { "id" => "29", "field_id" => "10", "group_no" => "9", "position" => "0", "_destroy" => "0", "value" => "" }, "38_12_3_1698255609" => { "id" => "38", "field_id" => "12", "group_no" => "1", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "43_13_3_1698255609" => { "id" => "43", "field_id" => "13", "group_no" => "1", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "52_12_3_1698255609" => { "id" => "52", "field_id" => "12", "group_no" => "2", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "53_13_3_1698255609" => { "id" => "53", "field_id" => "13", "group_no" => "2", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "40_12_3_1698255609" => { "id" => "40", "field_id" => "12", "group_no" => "3", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "45_13_3_1698255609" => { "id" => "45", "field_id" => "13", "group_no" => "3", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "114_12_3_1698255609" => { "id" => "114", "field_id" => "12", "group_no" => "4", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "115_13_3_1698255609" => { "id" => "115", "field_id" => "13", "group_no" => "4", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "116_12_3_1698255609" => { "id" => "116", "field_id" => "12", "group_no" => "5", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "117_13_3_1698255609" => { "id" => "117", "field_id" => "13", "group_no" => "5", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "118_12_3_1698255609" => { "id" => "118", "field_id" => "12", "group_no" => "6", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "119_13_3_1698255609" => { "id" => "119", "field_id" => "13", "group_no" => "6", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "124_12_3_1698255609" => { "id" => "124", "field_id" => "12", "group_no" => "8", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "125_13_3_1698255609" => { "id" => "125", "field_id" => "13", "group_no" => "8", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "42_12_3_1698255609" => { "id" => "42", "field_id" => "12", "group_no" => "9", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "47_13_3_1698255609" => { "id" => "47", "field_id" => "13", "group_no" => "9", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "128_12_3_1698255609" => { "id" => "128", "field_id" => "12", "group_no" => "1694349167", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "129_13_3_1698255609" => { "id" => "129", "field_id" => "13", "group_no" => "1694349167", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "134_12_3_1698255609" => { "id" => "134", "field_id" => "12", "group_no" => "1694349700", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "135_13_3_1698255609" => { "id" => "135", "field_id" => "13", "group_no" => "1694349700", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "74_21_5_1698255609" => { "id" => "74", "field_id" => "21", "group_no" => "999", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "75_22_5_1698255609" => { "id" => "75", "field_id" => "22", "group_no" => "999", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/5861saftxedfcsxiypoarzuvb3h1" }, "90_21_5_1698255609" => { "id" => "90", "field_id" => "21", "group_no" => "1694257623", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "91_22_5_1698255609" => { "id" => "91", "field_id" => "22", "group_no" => "1694257623", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/xzcrlyfy8q77mvagq1hrbewpnkme" }, "92_21_5_1698255609" => { "id" => "92", "field_id" => "21", "group_no" => "1694257687", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "93_22_5_1698255609" => { "id" => "93", "field_id" => "22", "group_no" => "1694257687", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/wom2kwjq8shg73di6zze1pr1tiyc" }, "94_21_5_1698255609" => { "id" => "94", "field_id" => "21", "group_no" => "1694257712", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "95_22_5_1698255609" => { "id" => "95", "field_id" => "22", "group_no" => "1694257712", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/1teyclp4azlicwcied6rfx95s454" }, "96_21_5_1698255609" => { "id" => "96", "field_id" => "21", "group_no" => "1694257759", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "97_22_5_1698255609" => { "id" => "97", "field_id" => "22", "group_no" => "1694257759", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/eib1sp7z07lqwikwugalcdtx01ye" }, "98_21_5_1698255609" => { "id" => "98", "field_id" => "21", "group_no" => "1694257784", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "99_22_5_1698255609" => { "id" => "99", "field_id" => "22", "group_no" => "1694257784", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/2ga7l4zczu57sgtanazrc0ateh5d" }, "100_21_5_1698255609" => { "id" => "100", "field_id" => "21", "group_no" => "1694257829", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "101_22_5_1698255609" => { "id" => "101", "field_id" => "22", "group_no" => "1694257829", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/6fv6ws0vdwwh7pebvg7s2dywp1h8" }, "102_21_5_1698255609" => { "id" => "102", "field_id" => "21", "group_no" => "1694257855", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "103_22_5_1698255609" => { "id" => "103", "field_id" => "22", "group_no" => "1694257855", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/1swbqrqtrrwwdhskfiubll6ibvxm" }, "104_21_5_1698255609" => { "id" => "104", "field_id" => "21", "group_no" => "1694257892", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "105_22_5_1698255609" => { "id" => "105", "field_id" => "22", "group_no" => "1694257892", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/b5qa55mqm0tlxmqylwo3kcyr1qcl" }, "106_21_5_1698255609" => { "id" => "106", "field_id" => "21", "group_no" => "1694257935", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "107_22_5_1698255609" => { "id" => "107", "field_id" => "22", "group_no" => "1694257935", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/b5w6nme2b0947x1q1bs2iwah1fcp" }, "108_21_5_1698255609" => { "id" => "108", "field_id" => "21", "group_no" => "1694257968", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "109_22_5_1698255609" => { "id" => "109", "field_id" => "22", "group_no" => "1694257968", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/sy7r3x6zenphiwn2rns1rb4y7xfo" }, "110_21_5_1698255609" => { "id" => "110", "field_id" => "21", "group_no" => "1694257992", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "111_22_5_1698255609" => { "id" => "111", "field_id" => "22", "group_no" => "1694257992", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/ttzrt4bdzwc28e5e2ljotrdvczya" }, "112_21_5_1698255609" => { "id" => "112", "field_id" => "21", "group_no" => "1694258009", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "113_22_5_1698255609" => { "id" => "113", "field_id" => "22", "group_no" => "1694258009", "position" => "0", "_destroy" => "0", "value" => "https://doctobooking-dev.s3.us-east-2.amazonaws.com/zk08or5qu9gl47a4slx25svzl2ll" }, "88_23_6_1698255609" => { "id" => "88", "field_id" => "23", "group_no" => "999", "position" => "0", "_destroy" => "0", "value" => { "en" => "", "es" => "" } }, "77_24_6_1698255609" => { "id" => "77", "field_id" => "24", "group_no" => "999", "position" => "0", "_destroy" => "0", "value" => "" } }, "page_type_id" => "1", "id" => "3" }










{"authenticity_token"=>"[FILTERED]", "gaco_cms_page"=>{"key"=>"home", "title"=>{"en"=>"Home Page", "es"=>"Home Page"}, "content"=>{"en"=>"", "es"=>"<div id=\"home_page\">\r\n<div class=\"main-slide d-flex align-items-center mb-5\" style=\"background-image: url('https://doctobooking-dev.s3.us-east-2.amazonaws.com/vazoq7u7xbc3i0v85qwe8mwtihgv');\">\r\n<div class=\"bg-white bg-opacity-75 p-3\">\r\n<h1>Bienvenido a <span class=\"text-primary\">DoctoBooking</span></h1>\r\n<h2>Sistema de reserva de citas m&eacute;dicas en l&iacute;nea</h2>\r\n<div class=\"d-flex\"><a class=\"btn btn-primary\" href=\"/doctors\">Reservar tu cita ahora</a></div>\r\n</div>\r\n</div>\r\n<div class=\"descr mb-4\">En Doctobooking, estamos redefiniendo la forma en que los doctores y pacientes se conectan y gestionan la atenci&oacute;n m&eacute;dica. Nuestra plataforma revolucionaria es impulsada por la inteligencia artificial (IA), lo que la hace novedosa y altamente efectiva. Facilitamos a los pacientes encontrar a los m&eacute;dicos adecuados, y a los doctores, simplificar y mejorar la atenci&oacute;n que brindan.</div>\r\n<h2>Para Pacientes</h2>\r\n<p>En Doctobooking, creemos que tu salud es una prioridad. Es por eso que hemos dise&ntilde;ado una plataforma innovadora que te brinda el control total de tu atenci&oacute;n m&eacute;dica. Aqu&iacute; hay algunas razones convincentes:</p>\r\n<div class=\"row text-center featured-services\">\r\n<div class=\"col-md-4 mb-2\">\r\n<div class=\"icon-box\">\r\n<div class=\"text-center text-secondary mb-2\"><span class=\"fa fa-users fa-3x\">&nbsp;</span></div>\r\n<h3 class=\"text-primaryt\">Amplia red de m&eacute;dicos</h3>\r\nEncuentra una amplia variedad de m&eacute;dicos y especialistas para que elijas al que mejor se adapte a tus necesidades (consultorio, a domicilio o virtual).</div>\r\n</div>\r\n<div class=\"col-md-4 mb-2\">\r\n<div class=\"icon-box\">\r\n<div class=\"text-center text-secondary mb-2\"><span class=\"fa fa-bolt fa-3x\">&nbsp;</span></div>\r\n<h3 class=\"text-primaryt\">Citas de forma f&aacute;cil y r&aacute;pida</h3>\r\nOlv&iacute;date de las largas esperas y las llamadas telef&oacute;nicas. Programa tus citas m&eacute;dicas en l&iacute;nea de manera r&aacute;pida y sencilla seg&uacute;n tu disponibilidad.</div>\r\n</div>\r\n<div class=\"col-md-4 mb-2\">\r\n<div class=\"icon-box\">\r\n<div class=\"text-center text-secondary mb-2\"><span class=\"fa fa-id-card fa-3x\">&nbsp;</span></div>\r\n<h3 class=\"text-primaryt\">Informaci&oacute;n de m&eacute;dicos</h3>\r\nExamina perfiles detallados de m&eacute;dicos que incluyen su experiencia, especialidad y opiniones de otros pacientes. Toma decisiones informadas sobre tu atenci&oacute;n m&eacute;dica.</div>\r\n</div>\r\n<div class=\"col-md-4 mb-2\">\r\n<div class=\"icon-box\">\r\n<div class=\"text-center text-secondary mb-2\"><span class=\"fa fa-bell fa-3x\">&nbsp;</span></div>\r\n<h3 class=\"text-primaryt\">Recordatorios y alertas</h3>\r\nMantente al tanto de tus citas m&eacute;dicas con recordatorios para no olvidar tus citas. Tambi&eacute;n, suscr&iacute;bete a alertas para estar al tanto de las nuevas citas disponibles.</div>\r\n</div>\r\n<div class=\"col-md-4 mb-2\">\r\n<div class=\"icon-box\">\r\n<div class=\"text-center text-secondary mb-2\"><span class=\"fa fa-magic fa-3x\">&nbsp;</span></div>\r\n<h3 class=\"text-primaryt\">Asesoramiento inteligente via IA</h3>\r\nObt&eacute;n descripciones de problemas m&eacute;dicos y recomendaciones de especialidades a trav&eacute;s de nuestra inteligencia artificial.</div>\r\n</div>\r\n<div class=\"col-md-4 mb-2\">\r\n<div class=\"icon-box\">\r\n<div class=\"text-center text-secondary mb-2\"><span class=\"fa fa-server fa-3x\">&nbsp;</span></div>\r\n<h3 class=\"text-primaryt\">Historial m&eacute;dico centralizado</h3>\r\nAccede a tu historial m&eacute;dico en un solo lugar. Lleva un registro de tus consultas pasadas y facilita la comunicaci&oacute;n con tus m&eacute;dicos.</div>\r\n</div>\r\n</div>\r\n<div class=\"text-center\"><a class=\"btn btn-outline-secondary\" href=\"[page_url page_key=patient-features]\">Ver m&aacute;s detalles</a></div>\r\n<div class=\"row mb-4 mt-2\">\r\n<div class=\"col-md-6 m-auto\">\r\n<div class=\"ratio ratio-16x9 border\" data-controller=\"embed-video\" data-src=\"https://www.youtube.com/watch?v=AZ-XNMs6yPs\">&nbsp;</div>\r\n</div>\r\n</div>\r\n<h2>Para Doctores</h2>\r\n<p>&iquest;Eres un profesional de la salud buscando simplificar tu pr&aacute;ctica m&eacute;dica? &iquest;Deseas una soluci&oacute;n novedosa que te elimine la carga de llamadas telef&oacute;nicas y agendas manuales? Doctobooking es la plataforma que ha llegado para cambiar la forma en que interact&uacute;as con tus pacientes y gestionas tus citas m&eacute;dicas. Aqu&iacute; tienes algunas razones por las que Doctobooking se convertir&aacute; en tu mejor aliado:</p>\r\n<div class=\"row\">\r\n<div class=\"col-md-4\">\r\n<div class=\"fw-bold\">Gesti&oacute;n Simplificada</div>\r\nElimina las llamadas telef&oacute;nicas y las agendas manuales. Configura tu disponibilidad en l&iacute;nea y ahorra tiempo.<hr></div>\r\n<div class=\"col-md-4\">\r\n<div class=\"fw-bold\">Varios tipos de consulta</div>\r\nOfrece diferentes modalidades de consulta: en el consultorio, en l&iacute;nea o a domicilio, todo en un solo lugar.<hr></div>\r\n<div class=\"col-md-4\">\r\n<div class=\"fw-bold\">Historiales Cl&iacute;nicos</div>\r\nAccede y guarda los historiales cl&iacute;nicos de tus pacientes de manera eficiente.<br><hr></div>\r\n<div class=\"col-md-4\">\r\n<div class=\"fw-bold\">Comunicaci&oacute;n &Aacute;gil</div>\r\nRecibe notificaciones y alertas v&iacute;a WhatsApp para estar siempre conectado con tus pacientes.<hr></div>\r\n<div class=\"col-md-4\">\r\n<div class=\"fw-bold\">Seguridad y Privacidad</div>\r\nNiveles de seguridad avanzados para proteger la informaci&oacute;n de tus pacientes.<br><hr></div>\r\n<div class=\"col-md-4\">\r\n<div class=\"fw-bold\">Atrae M&aacute;s Pacientes</div>\r\nDestaca tu perfil en internet y permite la difusi&oacute;n del mismo a trav&eacute;s de las redes sociales.<hr></div>\r\n</div>\r\n<div class=\"text-center\"><a class=\"btn btn-outline-secondary\" href=\"[page_url page_key=doctors-features]\">Ver m&aacute;s detalles</a></div>\r\n<div class=\"row mt-2\">\r\n<div class=\"col-md-6 m-auto\">\r\n<div class=\"ratio ratio-16x9 border\" data-controller=\"embed-video\" data-src=\"https://www.youtube.com/watch?v=phY0ipnxMzE\">&nbsp;</div>\r\n</div>\r\n</div>\r\n</div>"}, "template"=>"", "summary"=>{"en"=>"", "es"=>""}, "photo_url"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/vazoq7u7xbc3i0v85qwe8mwtihgv"}, "field_values_attributes"=>{"78_25_1_1698256354"=>{"id"=>"78", "field_id"=>"25", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "79_26_1_1698256354"=>{"id"=>"79", "field_id"=>"26", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "137_27_1_1698256354"=>{"id"=>"137", "field_id"=>"27", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "1_1_1_1698256354"=>{"id"=>"1", "field_id"=>"1", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "58_14_1_1698256354"=>{"id"=>"58", "field_id"=>"14", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "2_2_1_1698256354"=>{"id"=>"2", "field_id"=>"2", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "59_15_1_1698256354"=>{"id"=>"59", "field_id"=>"15", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "3_3_1_1698256354"=>{"id"=>"3", "field_id"=>"3", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "4_4_1_1698256354"=>{"id"=>"4", "field_id"=>"4", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "5_5_1_1698256354"=>{"id"=>"5", "field_id"=>"5", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "48_6_1_1698256354"=>{"id"=>"48", "field_id"=>"6", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/vazoq7u7xbc3i0v85qwe8mwtihgv"}, "49_7_1_1698256354"=>{"id"=>"49", "field_id"=>"7", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>""}, "64_16_1_1698256354"=>{"id"=>"64", "field_id"=>"16", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "65_17_1_1698256354"=>{"id"=>"65", "field_id"=>"17", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}},
"66_19_1_1698256354"=>{"id"=>"66", "field_id"=>"19", "group_no"=>"0", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>"<p><a href=\"[page_url page_key=api-connection]\">Integraci&oacute;n</a> | <a href=\"[page_url key=jobs]\">Vacancias</a> | <a href=\"[page_url key=pricing]\">Precios</a> | <a href=\"[page_url key=procedure]\">Como funciona?</a> | <a href=\"[page_url key=policy]\">Pol&iacute;ticas de uso</a></p>"}}, "57_11_2_1698256354"=>{"id"=>"57", "field_id"=>"11", "group_no"=>"1", "position"=>"0", "_destroy"=>"0", "value"=>"fa-home"}, "54_8_2_1698256354"=>{"id"=>"54", "field_id"=>"8", "group_no"=>"1", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "55_9_2_1698256354"=>{"id"=>"55", "field_id"=>"9", "group_no"=>"1", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "56_10_2_1698256354"=>{"id"=>"56", "field_id"=>"10", "group_no"=>"1", "position"=>"0", "_destroy"=>"0", "value"=>""}, "31_11_2_1698256354"=>{"id"=>"31", "field_id"=>"11", "group_no"=>"3", "position"=>"0", "_destroy"=>"0", "value"=>"fa-map-location"}, "7_8_2_1698256354"=>{"id"=>"7", "field_id"=>"8", "group_no"=>"3", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "15_9_2_1698256354"=>{"id"=>"15", "field_id"=>"9", "group_no"=>"3", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "23_10_2_1698256355"=>{"id"=>"23", "field_id"=>"10", "group_no"=>"3", "position"=>"0", "_destroy"=>"0", "value"=>""}, "32_11_2_1698256355"=>{"id"=>"32", "field_id"=>"11", "group_no"=>"4", "position"=>"0", "_destroy"=>"0", "value"=>"fa-calendar-day"}, "8_8_2_1698256355"=>{"id"=>"8", "field_id"=>"8", "group_no"=>"4", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "16_9_2_1698256355"=>{"id"=>"16", "field_id"=>"9", "group_no"=>"4", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "24_10_2_1698256355"=>{"id"=>"24", "field_id"=>"10", "group_no"=>"4", "position"=>"0", "_destroy"=>"0", "value"=>""}, "33_11_2_1698256355"=>{"id"=>"33", "field_id"=>"11", "group_no"=>"5", "position"=>"0", "_destroy"=>"0", "value"=>"fa-star"}, "9_8_2_1698256355"=>{"id"=>"9", "field_id"=>"8", "group_no"=>"5", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "17_9_2_1698256355"=>{"id"=>"17", "field_id"=>"9", "group_no"=>"5", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "25_10_2_1698256355"=>{"id"=>"25", "field_id"=>"10", "group_no"=>"5", "position"=>"0", "_destroy"=>"0", "value"=>""}, "34_11_2_1698256355"=>{"id"=>"34", "field_id"=>"11", "group_no"=>"6", "position"=>"0", "_destroy"=>"0", "value"=>"fa-circle-dollar-to-slot"}, "10_8_2_1698256355"=>{"id"=>"10", "field_id"=>"8", "group_no"=>"6", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "18_9_2_1698256355"=>{"id"=>"18", "field_id"=>"9", "group_no"=>"6", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "26_10_2_1698256355"=>{"id"=>"26", "field_id"=>"10", "group_no"=>"6", "position"=>"0", "_destroy"=>"0", "value"=>""}, "35_11_2_1698256355"=>{"id"=>"35", "field_id"=>"11", "group_no"=>"7", "position"=>"0", "_destroy"=>"0", "value"=>"fa-globe"}, "11_8_2_1698256355"=>{"id"=>"11", "field_id"=>"8", "group_no"=>"7", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "19_9_2_1698256355"=>{"id"=>"19", "field_id"=>"9", "group_no"=>"7", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "27_10_2_1698256355"=>{"id"=>"27", "field_id"=>"10", "group_no"=>"7", "position"=>"0", "_destroy"=>"0", "value"=>""}, "36_11_2_1698256355"=>{"id"=>"36", "field_id"=>"11", "group_no"=>"8", "position"=>"0", "_destroy"=>"0", "value"=>"fa-eye"}, "12_8_2_1698256355"=>{"id"=>"12", "field_id"=>"8", "group_no"=>"8", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "20_9_2_1698256355"=>{"id"=>"20", "field_id"=>"9", "group_no"=>"8", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "28_10_2_1698256355"=>{"id"=>"28", "field_id"=>"10", "group_no"=>"8", "position"=>"0", "_destroy"=>"0", "value"=>""}, "37_11_2_1698256355"=>{"id"=>"37", "field_id"=>"11", "group_no"=>"9", "position"=>"0", "_destroy"=>"0", "value"=>"fa-bell"}, "13_8_2_1698256355"=>{"id"=>"13", "field_id"=>"8", "group_no"=>"9", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "21_9_2_1698256355"=>{"id"=>"21", "field_id"=>"9", "group_no"=>"9", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "29_10_2_1698256355"=>{"id"=>"29", "field_id"=>"10", "group_no"=>"9", "position"=>"0", "_destroy"=>"0", "value"=>""}, "38_12_3_1698256355"=>{"id"=>"38", "field_id"=>"12", "group_no"=>"1", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "43_13_3_1698256355"=>{"id"=>"43", "field_id"=>"13", "group_no"=>"1", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "52_12_3_1698256355"=>{"id"=>"52", "field_id"=>"12", "group_no"=>"2", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "53_13_3_1698256355"=>{"id"=>"53", "field_id"=>"13", "group_no"=>"2", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "40_12_3_1698256355"=>{"id"=>"40", "field_id"=>"12", "group_no"=>"3", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "45_13_3_1698256355"=>{"id"=>"45", "field_id"=>"13", "group_no"=>"3", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "114_12_3_1698256355"=>{"id"=>"114", "field_id"=>"12", "group_no"=>"4", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "115_13_3_1698256355"=>{"id"=>"115", "field_id"=>"13", "group_no"=>"4", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "116_12_3_1698256355"=>{"id"=>"116", "field_id"=>"12", "group_no"=>"5", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "117_13_3_1698256355"=>{"id"=>"117", "field_id"=>"13", "group_no"=>"5", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "118_12_3_1698256355"=>{"id"=>"118", "field_id"=>"12", "group_no"=>"6", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "119_13_3_1698256355"=>{"id"=>"119", "field_id"=>"13", "group_no"=>"6", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "124_12_3_1698256355"=>{"id"=>"124", "field_id"=>"12", "group_no"=>"8", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "125_13_3_1698256355"=>{"id"=>"125", "field_id"=>"13", "group_no"=>"8", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "42_12_3_1698256355"=>{"id"=>"42", "field_id"=>"12", "group_no"=>"9", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "47_13_3_1698256355"=>{"id"=>"47", "field_id"=>"13", "group_no"=>"9", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "128_12_3_1698256355"=>{"id"=>"128", "field_id"=>"12", "group_no"=>"1694349167", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "129_13_3_1698256355"=>{"id"=>"129", "field_id"=>"13", "group_no"=>"1694349167", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "134_12_3_1698256355"=>{"id"=>"134", "field_id"=>"12", "group_no"=>"1694349700", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "135_13_3_1698256355"=>{"id"=>"135", "field_id"=>"13", "group_no"=>"1694349700", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "74_21_5_1698256355"=>{"id"=>"74", "field_id"=>"21", "group_no"=>"999", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "75_22_5_1698256355"=>{"id"=>"75", "field_id"=>"22", "group_no"=>"999", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/5861saftxedfcsxiypoarzuvb3h1"}, "90_21_5_1698256355"=>{"id"=>"90", "field_id"=>"21", "group_no"=>"1694257623", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "91_22_5_1698256355"=>{"id"=>"91", "field_id"=>"22", "group_no"=>"1694257623", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/xzcrlyfy8q77mvagq1hrbewpnkme"}, "92_21_5_1698256355"=>{"id"=>"92", "field_id"=>"21", "group_no"=>"1694257687", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "93_22_5_1698256355"=>{"id"=>"93", "field_id"=>"22", "group_no"=>"1694257687", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/wom2kwjq8shg73di6zze1pr1tiyc"}, "94_21_5_1698256355"=>{"id"=>"94", "field_id"=>"21", "group_no"=>"1694257712", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "95_22_5_1698256355"=>{"id"=>"95", "field_id"=>"22", "group_no"=>"1694257712", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/1teyclp4azlicwcied6rfx95s454"}, "96_21_5_1698256355"=>{"id"=>"96", "field_id"=>"21", "group_no"=>"1694257759", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "97_22_5_1698256355"=>{"id"=>"97", "field_id"=>"22", "group_no"=>"1694257759", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/eib1sp7z07lqwikwugalcdtx01ye"}, "98_21_5_1698256355"=>{"id"=>"98", "field_id"=>"21", "group_no"=>"1694257784", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "99_22_5_1698256355"=>{"id"=>"99", "field_id"=>"22", "group_no"=>"1694257784", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/2ga7l4zczu57sgtanazrc0ateh5d"}, "100_21_5_1698256355"=>{"id"=>"100", "field_id"=>"21", "group_no"=>"1694257829", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "101_22_5_1698256355"=>{"id"=>"101", "field_id"=>"22", "group_no"=>"1694257829", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/6fv6ws0vdwwh7pebvg7s2dywp1h8"}, "102_21_5_1698256355"=>{"id"=>"102", "field_id"=>"21", "group_no"=>"1694257855", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "103_22_5_1698256355"=>{"id"=>"103", "field_id"=>"22", "group_no"=>"1694257855", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/1swbqrqtrrwwdhskfiubll6ibvxm"}, "104_21_5_1698256355"=>{"id"=>"104", "field_id"=>"21", "group_no"=>"1694257892", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "105_22_5_1698256355"=>{"id"=>"105", "field_id"=>"22", "group_no"=>"1694257892", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/b5qa55mqm0tlxmqylwo3kcyr1qcl"}, "106_21_5_1698256355"=>{"id"=>"106", "field_id"=>"21", "group_no"=>"1694257935", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "107_22_5_1698256355"=>{"id"=>"107", "field_id"=>"22", "group_no"=>"1694257935", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/b5w6nme2b0947x1q1bs2iwah1fcp"}, "108_21_5_1698256355"=>{"id"=>"108", "field_id"=>"21", "group_no"=>"1694257968", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "109_22_5_1698256355"=>{"id"=>"109", "field_id"=>"22", "group_no"=>"1694257968", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/sy7r3x6zenphiwn2rns1rb4y7xfo"}, "110_21_5_1698256355"=>{"id"=>"110", "field_id"=>"21", "group_no"=>"1694257992", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "111_22_5_1698256355"=>{"id"=>"111", "field_id"=>"22", "group_no"=>"1694257992", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/ttzrt4bdzwc28e5e2ljotrdvczya"}, "112_21_5_1698256355"=>{"id"=>"112", "field_id"=>"21", "group_no"=>"1694258009", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "113_22_5_1698256355"=>{"id"=>"113", "field_id"=>"22", "group_no"=>"1694258009", "position"=>"0", "_destroy"=>"0", "value"=>"https://doctobooking-dev.s3.us-east-2.amazonaws.com/zk08or5qu9gl47a4slx25svzl2ll"}, "88_23_6_1698256355"=>{"id"=>"88", "field_id"=>"23", "group_no"=>"999", "position"=>"0", "_destroy"=>"0", "value"=>{"en"=>"", "es"=>""}}, "77_24_6_1698256355"=>{"id"=>"77", "field_id"=>"24", "group_no"=>"999", "position"=>"0", "_destroy"=>"0", "value"=>""}}, "page_type_id"=>"1", "id"=>"3"}