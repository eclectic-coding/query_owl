require "turbo-rails"
require "importmap-rails"

module QueryOwl
  class Engine < ::Rails::Engine
    isolate_namespace QueryOwl
    config.generators.api_only = true

    initializer "query_owl.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
      end
    end

    initializer "query_owl.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end

    initializer "query_owl.subscribe" do
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        next unless QueryOwl.config.enabled

        event = ActiveSupport::Notifications::Event.new(*args)
        QueryTracker.record(event)
      end
    end

    initializer "query_owl.request_tracking" do |app|
      app.middleware.use(Middleware)
    end

    config.after_initialize do
      ActiveRecord::Associations::Preloader.prepend(Module.new do
        def initialize(records:, associations:, **kwargs)
          if QueryOwl::EagerLoadTracker.tracking? && records.any?
            model_name = records.first.class.name
            Array(associations).each do |assoc|
              QueryOwl::EagerLoadTracker.record_preload(model_name, assoc)
            end
          end
          super
        end

        def call
          Thread.current[:query_owl_preloading] = true
          super
        ensure
          Thread.current[:query_owl_preloading] = false
        end
      end)

      ActiveRecord::Base.prepend(Module.new do
        def association(name)
          unless Thread.current[:query_owl_preloading]
            QueryOwl::EagerLoadTracker.record_access(self.class.name, name)
          end
          super
        end
      end)
    end
  end
end
