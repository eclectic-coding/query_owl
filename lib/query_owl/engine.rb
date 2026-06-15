module QueryOwl
  class Engine < ::Rails::Engine
    isolate_namespace QueryOwl
    config.generators.api_only = true

    initializer "query_owl.subscribe" do
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        next unless QueryOwl.config.enabled

        event = ActiveSupport::Notifications::Event.new(*args)
        QueryTracker.record(event)
      end
    end

    initializer "query_owl.request_tracking" do |app|
      app.middleware.use(Class.new do
        def initialize(rack_app)
          @app = rack_app
        end

        def call(env)
          return @app.call(env) unless QueryOwl.config.enabled

          QueryTracker.start!
          @app.call(env)
        ensure
          queries = QueryTracker.stop!
          events  = Detector.detect_n_plus_one(queries) + Detector.detect_slow_queries(queries)
          Logger.log_events(events)
        end
      end)
    end
  end
end
