# frozen_string_literal: true

module GacoCms
  module Admin
    class FieldsController < BaseController
      before_action :set_field

      def tpl
        value = @field.field_values.new(group_no: params[:group_no])
        render partial: '/gaco_cms/admin/fields/render/field', locals: { value: value }
      end

      private

      def set_field
        @field = Field.find(params[:id])
      end
    end
  end
end
