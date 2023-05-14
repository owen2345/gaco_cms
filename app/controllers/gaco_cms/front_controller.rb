# frozen_string_literal: true

module GacoCms
  class FrontController < GacoCms::Config.parent_front_controller.constantize
    layout :gaco_set_layout
    before_action :gaco_set_locale
    helper_method :theme_path_for
    helper_method :current_theme

    def index
    end

    def page
      key = params[:page_id]
      @page = Page.by_key(key) || Page.find(key)
    end

    private

    def gaco_set_layout
      instance_eval(&Config.front_layout)
    end

    def gaco_set_locale
      session[:gaco_locale] = params[:locale] if params[:locale].present?
      I18n.locale = session[:gaco_locale] if session[:gaco_locale]
    end

    def current_theme
      @current_theme ||= Theme.current
    end
  end
end
