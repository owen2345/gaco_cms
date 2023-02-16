# frozen_string_literal: true

module GacoCms
  module Admin
    class PageTypesController < BaseController
      before_action :set_page_type, only: %i[edit update destroy]
      before_action { add_breadcrumb(PageType.human_name(count: 2), url_for(action: :index)) }

      def index
        @page_types = PageType.all.title_ordered
      end

      def new
        @page_type = PageType.new
        render :form
      end

      def create
        page_type = PageType.new(page_type_params)
        if page_type.save
          redirect_to url_for(action: :index), notice: 'PageType saved'
        else
          render inline: page_type.errors.full_message.join(', ')
        end
      end

      def edit
        render :form
      end

      def update
        if @page_type.update(page_type_params)
          redirect_to url_for(action: :index), notice: 'PageType saved'
        else
          render inline: @page_type.errors.full_message.join(', ')
        end
      end

      def destroy
        @page_type.destroy!
        redirect_to url_for(action: :index), notice: 'PageType destroyed'
      end

      private

      def page_type_params
        params.require(:gaco_cms_page_type)
              .permit(:key, :template, title: permitted_locales)
      end

      def set_page_type
        @page_type = PageType.find(params[:id])
      end
    end
  end
end
