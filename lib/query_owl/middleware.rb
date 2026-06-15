module QueryOwl
  class Middleware
    def initialize(app)
      @app = app
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
  end
end
