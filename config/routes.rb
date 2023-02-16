# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :gaco_cms, path: GacoCms::Config.url_path do
    namespace :admin do
      get '/', to: 'base#index'
      post 'upload_file', controller: 'base'
      resources :page_types do
        resources :pages
      end
      resources :field_groups do
        get :tpl, on: :member
        get :new_field, on: :collection
      end
      resources :fields, only: [] do
        get :tpl, on: :member
      end
      resources :themes
    end

    # frontend
    get '/', to: 'front#index'
    get 'page/:page_id', as: 'page', to: 'front#page'
  end
end
