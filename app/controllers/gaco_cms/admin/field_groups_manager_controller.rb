# frozen_string_literal: true

module GacoCms
  module Admin
    class FieldGroupsManagerController < BaseController
      before_action :set_record, only: %i[index update]

      # @option record_type [String]
      # @option record_id [Integer]
      # @option reload_frame [String]
      def index
        @groups = @record.field_groups
      end

      def group_tpl
        @group = FieldGroup.new
        render partial: 'group', locals: { group: @group }
      end

      # @option kind [String]
      def field_tpl
        field = Field.new(kind: params[:kind])
        render partial: 'field', locals: { field: field, parent_name: params[:parent_name] }
      end

      def update
        if @record.update(groups_params)
          render inline: ''
        else
          render inline: @record.errors.full_messages.join(', ')
        end
      end

      private

      # TODO: whitelist record_types
      def set_record
        @record = params[:record_type].constantize.find(params[:record_id])
      end

      def groups_params
        fix_groups_fields
        fix_fields_params
        fields_attrs = [:id, :kind, :key, :repeat, :required, :translatable, :position, :_destroy,
                        :title, :description, { def_value: permitted_locales }]
        params.require(:groups_manager)
              .permit(field_groups_attributes: [:id, :key, :record_id, :record_type, :repeat, :position, :_destroy, :template,
                                                :title, :description, fields_attributes: fields_attrs])
      end

      def fix_groups_fields
        params[:groups_manager][:field_groups_attributes] = params[:groups_manager][:field_groups_attributes].values
      end

      def fix_fields_params
        params[:groups_manager][:field_groups_attributes].each do |group_attrs|
          group_attrs[:fields_attributes] = (group_attrs[:fields_attributes] || {}).values
          group_attrs[:fields_attributes].each do |field_attr|
            def_val = field_attr[:def_value]
            field_attr[:def_value] = { en: def_val } if def_val && !def_val.is_a?(Hash)
          end
        end
      end
    end
  end
end
