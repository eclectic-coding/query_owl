module QueryOwl
  class Engine < ::Rails::Engine
    isolate_namespace QueryOwl
    config.generators.api_only = true
  end
end
