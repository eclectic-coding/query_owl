module QueryOwl
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless QueryOwl.config.enabled

      QueryTracker.start!
      EagerLoadTracker.start!
      @app.call(env)
    ensure
      queries     = QueryTracker.stop!
      eager_data  = EagerLoadTracker.stop!
      events      = Detector.detect_n_plus_one(queries) +
                    Detector.detect_slow_queries(queries) +
                    Detector.detect_unused_eager_loads(eager_data)
      Logger.log_events(events)
      Logger.log_summary(events)
    end
  end
end
