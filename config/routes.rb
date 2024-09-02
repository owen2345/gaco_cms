# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :gaco_cms, path: GacoCms::Config.url_path do
    namespace :admin do
      get '/', to: 'base#index'
      post 'upload_file', controller: 'base'
      resources :page_types do
        resources :pages
      end
      resources :field_groups_manager, only: %i[index update] do
        get :group_tpl, on: :collection
        get :field_tpl, on: :collection
      end
      resources :field_groups_renderer, only: :index do
        get :render_group, on: :collection
        get :render_field, on: :collection
      end
      resources :themes
    end

    # frontend
    get '/', to: 'front#index'
    get 'page/:page_id', as: 'page', to: 'front#page'
    get ':page_title-:page_id', as: 'titled_page', to: 'front#page'
    get ':type_title/:page_title-:page_id', as: 'type_titled_page', to: 'front#page'
  end
end
