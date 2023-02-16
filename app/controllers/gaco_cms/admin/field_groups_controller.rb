# frozen_string_literal: true

module GacoCms
  module Admin
    class FieldGroupsController < BaseController
      before_action :set_group, except: %i[index new create new_field]
      before_action { add_breadcrumb(FieldGroup.human_name(count: 2), url_for(action: :index)) }

      def index
        @groups = FieldGroup.ordered.all
      end

      def new
        @group = FieldGroup.new
        render :form
      end

      def create
        group = FieldGroup.new(group_params)
        if group.save
          redirect_to url_for(action: :index), notice: 'Group saved'
        else
          render inline: group.errors.full_messages.join(', ')
        end
      end

      def edit
        render :form
      end

      def update
        if @group.update(group_params)
          redirect_to url_for(action: :index), notice: 'Group updated'
        else
          render inline: @group.errors.full_messages.join(', ')
        end
      end

      def destroy
        @group.destroy!
        redirect_to url_for(action: :index), notice: 'Group destroyed'
      end

      def tpl
        locals = { group: @group, field_values: FieldValue.none, group_no: Time.current.to_i }
        render partial: '/gaco_cms/admin/fields/render/group', locals: locals
      end

      def new_field
        field = Field.new(kind: params[:kind])
        render partial: 'field', locals: { field: field }
      end

      private

      def group_params
        fix_record_param
        fix_fields_params
        params.require(:gaco_cms_field_group)
              .permit(:key, :record_id, :record_type, :repeat, :position,
                      title: permitted_locales, description: permitted_locales,
                      fields_attributes: [:id, :kind, :key, :repeat, :required,
                                          :translatable, :position, :_destroy,
                                          { title: permitted_locales, def_value: permitted_locales,
                                            description: permitted_locales }])
      end

      def set_group
        @group = FieldGroup.find(params[:id])
      end

      def fix_record_param
        record = params[:gaco_cms_field_group].delete(:record).to_s
        params[:gaco_cms_field_group][:record_type], params[:gaco_cms_field_group][:record_id] = record.split('/')
      end

      def fix_fields_params
        items = (params[:fields_attributes] || {}).values
        items.each do |item|
          def_val = item[:def_value]
          item[:def_value] = { en: def_val } if def_val && !def_val.is_a?(Hash)
        end
        params[:gaco_cms_field_group][:fields_attributes] = items
      end
    end
  end
end
