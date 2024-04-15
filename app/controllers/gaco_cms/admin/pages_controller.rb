# frozen_string_literal: true

module GacoCms
  module Admin
    class PagesController < BaseController
      before_action :set_page_type
      before_action :set_page, only: %i[edit update destroy]
      before_action :set_breadcrumb

      def index
        @pages = @page_type.pages.order(updated_at: :desc)
      end

      def new
        @page = @page_type.pages.new
      end

      def create
        page = @page_type.pages.new(page_params)
        if page.save
          redirect_to url_for(action: :edit, id: page), notice: 'Page created'
        else
          render inline: page.errors.full_messages.join(', ')
        end
      end

      def edit; end

      def update
        if @page.update(page_params)
          flash[:notice] = 'Page saved'
          render inline: ''
        else
          render inline: @page.errors.full_messages.join(', ')
        end
      end

      def destroy
        @page.destroy!
        redirect_to url_for(action: :index), notice: 'Page destroyed'
      end

      private

      def page_params
        fix_fields_values_param(:gaco_cms_page)
        params.require(:gaco_cms_page)
              .permit(:key, :template, :photo_url,
                      content: permitted_locales, summary: permitted_locales, title: permitted_locales,
                      field_values_attributes: permitted_field_values_params)
      end

      def set_page
        @page = @page_type.pages.find(params[:id])
      end

      def set_page_type
        @page_type = PageType.find_by(key: params[:page_type_id]) || PageType.find(params[:page_type_id])
      end

      def set_breadcrumb
        type_id = @page_type ? @page_type.id : @page.page_type_id
        name = @page_type ? @page_type.title : @page.page_type.title
        add_breadcrumb(name, edit_gaco_cms_admin_page_type_path(type_id))

        url = gaco_cms_admin_page_type_pages_path(page_type_id: @page_type ? @page_type.id : @page.page_type_id)
        add_breadcrumb(Page.human_name(count: 2), url)
      end
    end
  end
end
