# frozen_string_literal: true

module GacoCms
  module Admin
    class ThemesController < BaseController
      before_action :set_theme, except: %i[index new create]
      before_action { add_breadcrumb(Theme.human_name(count: 2), url_for(action: :index)) }

      def index
        @themes = Theme.ordered.all
      end

      def new
        @theme = Theme.new
      end

      def create
        theme = Theme.new(theme_params)
        if theme.save
          redirect_to url_for(action: :edit, id: theme), notice: 'Theme created'
        else
          render inline: theme.errors.full_messages.join(', ')
        end
      end

      def edit; end

      def update
        if @theme.update(theme_params)
          render inline: ''
        else
          render inline: @theme.errors.full_messages.join(', ')
        end
      end

      def destroy
        @theme.destroy!
        redirect_to url_for(action: :index), notice: 'Theme destroyed'
      end

      private

      def theme_params
        fix_fields_values_param(:gaco_cms_theme)
        params.require(:gaco_cms_theme)
              .permit(:key, :title, :active,
                      field_values_attributes: permitted_field_values_params)
      end

      def set_theme
        @theme = Theme.find(params[:id])
      end
    end
  end
end
