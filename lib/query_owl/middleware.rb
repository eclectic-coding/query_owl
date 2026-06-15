module QueryOwl
  class Middleware
    def initialize(app)
      @app = app
    end

    def raise_on_n_plus_one!(events)
      event = events.find { |e| e[:type] == :n_plus_one }
      return unless event

      raise NPlusOneError, "N+1 detected: #{event[:sql]} (#{event[:count]} times) #{event[:backtrace].first}"
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
      events.each { |e| EventStore.push(e) }
      FileLogger.append(events)
      raise_on_n_plus_one!(events) if QueryOwl.config.raise_on_n_plus_one
    end
  end
end
