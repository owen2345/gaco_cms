# frozen_string_literal: true

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
      pg_sample = '[page_group key="my_key"] or [page_group key="my_key" page_id=10 wrapper="<div class=\'row\'>{yield}</div>"]'
      {
        page_content: { render: method(:page_content_parser), sample: '[page_content] or [page_content page_id=10]' },
        page_title: { render: method(:page_title_parser), sample: '[page_title] or [page_title page_id=10]' },
        page_photo: { render: method(:page_photo_parser), sample: pp_sample },
        page_field: { render: method(:page_field_parser), sample: pf_sample },
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
      "(\\[(#{shortcodes.keys.join('|')})((\s)((?!\\]).)*|)\\])"
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
