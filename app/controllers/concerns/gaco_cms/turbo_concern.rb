module GacoCms
  module TurboConcern
    extend ActiveSupport::Concern
    included do
      around_action :parse_turbo_frame, if: -> { turbo_frame_id && request.get? }
    end

    private

    def turbo_frame_id
      request.headers['Turbo-Frame']
    end

    # fix: automatically render content turbo frame caller tag
    def parse_turbo_frame
      begin
        yield
        render_turbo_content(turbo_frame_id) { response.body }
      end
    end

    def render_turbo_content(target, &block)
      response.content_type = 'text/vnd.turbo-stream.html'
      content = "#{block.call}#{turbo_flash_messages}"
      response.body = turbo_stream_with(:update, content, target: target)
    end

    # @param e (Exception)
    def print_turbo_error(e)
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      dev_msg = Rails.env.production? ? '' : " ==> #{e.message}"
      flash[:error] = "#{t('common.internal_error')}. #{dev_msg}"
    end

    # @return [String]
    def turbo_flash_messages
      flash_messages = render_to_string(partial: '/layouts/gaco_cms/flash_messages')
      return '' unless flash_messages.present?

      content = turbo_stream_with(:update, flash_messages, target: :toasts)
      flash.clear # clear streamed flash messages
      content
    end

    def turbo_stream_with(action, content, target: nil, targets: nil)
      "<turbo-stream action='#{action}' #{"target='#{target}'" if target} #{"targets='#{targets}'" if targets}>
        <template>#{content}</template>
      </turbo-stream>"
    end
  end
end
