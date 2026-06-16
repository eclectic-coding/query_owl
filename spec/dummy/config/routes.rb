Rails.application.routes.draw do
  mount QueryOwl::Engine => "/query_owl"

  resources :widgets, only: [ :index, :show ] do
    collection { get :unused }
  end
end