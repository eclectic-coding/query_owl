QueryOwl::Engine.routes.draw do
  get "slow_queries", to: "slow_queries#index"
end
