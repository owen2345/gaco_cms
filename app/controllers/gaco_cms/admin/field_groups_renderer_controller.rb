# frozen_string_literal: true

module GacoCms
  module Admin
    class FieldGroupsRendererController < BaseController
      before_action :set_record, only: %i[index update]

      def index
        @groups = @record.field_groups
        @groups = @record.page_type.field_groups if params[:parent] && @record.is_a?(Page)
      end

      def render_group
        group = FieldGroup.find(params[:group_id])
        locals = { group: group, field_values: FieldValue.none, group_no: Time.current.to_i }
        render partial: 'group', locals: locals
      end

      def render_field
        field = Field.find(params[:field_id])
        value = field.field_values.new(group_no: params[:group_no])
        render partial: 'field', locals: { value: value }
      end

      private

      # TODO: whitelist record_types
      def set_record
        @record = params[:record_type].constantize.find(params[:record_id])
      end
    end
  end
end
