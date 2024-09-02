module GacoCms
  module TurboConcern
    extend ActiveSupport::Concern
    included do
      layout -> { false if turbo_frame_request? || request.headers['No-Layout'] }
      around_action :parse_turbo_frame
    end

    private

    def parse_turbo_frame
      yield
      is_redirect = response.status == 302
      includes_layout = response.body.include?('<html>')
      return if is_redirect || includes_layout || %w[*/* html].none? { request.format.to_s.include?(_1) }

      render_turbo_content(response.body)
    end

    def render_turbo_content(content, turbo_target = turbo_frame_request_id) # rubocop:disable Metrics/AbcSize
      turbo_action = request.headers['Turbo-Response-Action'] || 'update'
      raise 'Invalid turbo action' if %w[update replace append append_all].exclude?(turbo_action)

      parse_turbo = turbo_target && response.status == 200 && !params[:turbo_response_skip]
      content = '' if params[:turbo_response_skip] # TODO: use headers instead
      content = "#{content}#{turbo_flash_response}"
      content = turbo_stream.send(turbo_action, turbo_target, content) if parse_turbo && !@skip_turbo_response_wrapper
      response.content_type = 'text/vnd.turbo-stream.html'
      response.body = content
    end

    # @return [String]
    def turbo_flash_response
      content = ''
      return content if @skip_turbo_response_flash

      flash_messages = render_to_string(partial: '/layouts/gaco_cms/flash_messages')
      # append: allows to persist flash messages
      content += turbo_stream.send(request.get? ? :append : :update, 'toasts', flash_messages)
      flash.clear # clear streamed flash messages
      content
    end

    def render_failure(model, run_turbo: false)
      error = model.is_a?(String) ? model : model.errors.full_messages.join('<br>')
      return render json: { error: }, status: :unprocessable_entity if request.format == 'json'

      if request.headers['X-Turbo-Request-Id'].present?
        flash[:error] = error
        render inline: '', status: :unprocessable_entity
        render_turbo_content(response.body) if run_turbo
      else
        @msg = error
        render '/dashboard/error'
      end
    end

    def turbo_request?
      request.headers['Turbo-Request'].present?
    end
  end
end
