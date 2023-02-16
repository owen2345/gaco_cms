# frozen_string_literal: true

module GacoCms
  module Admin
    class BaseController < GacoCms::Config.parent_backend_controller.constantize
      skip_before_action :verify_authenticity_token, only: :upload_file
      before_action :gaco_check_authentication
      before_action { add_breadcrumb(:home, gaco_cms_admin_path) }
      layout :gaco_set_layout
      helper_method :ajax_request?

      def upload_file
        file = GacoCms::MediaFile.new(file: params[:file])
        if file.save
          render json: { location: file.url }
        else
          render json: { error: file.errors.full_message.join(', ') }
        end
      end

      def index; end

      private

      def gaco_set_layout
        ajax_request? ? false : 'gaco_cms/admin'
      end

      def ajax_request?
        request.headers[:xhr].present?
      end

      def add_breadcrumb(label, url = nil)
        @breadcrumbs ||= []
        @breadcrumbs << [label, url]
      end

      private

      def permitted_locales
        I18n.available_locales
      end

      def permitted_field_values_params
        [:id, :field_id, :group_no, :position, :_destroy, { value: permitted_locales }]
      end

      def fix_fields_values_param(param_key)
        values = params[:field_values_attributes]&.values || []
        values.each do |v|
          v[:value] = {  I18n.locale => v[:value] } unless v[:value].is_a?(Hash)
        end
        params[param_key][:field_values_attributes] = values
      end

      def gaco_check_authentication
        # TODO: check admin authentication
      end
    end
  end
end
