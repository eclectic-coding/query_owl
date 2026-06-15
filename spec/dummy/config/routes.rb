Rails.application.routes.draw do
  mount QueryOwl::Engine => "/query_owl"
end
