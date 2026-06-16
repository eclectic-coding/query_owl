module QueryOwl
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      tracking = false
      return @app.call(env) unless QueryOwl.config.enabled
      return @app.call(env) if ignored_path?(env["PATH_INFO"])

      tracking = true
      QueryTracker.start!
      EagerLoadTracker.start!
      @app.call(env)
    ensure
      if tracking
        params     = env["action_dispatch.request.path_parameters"] || {}
        RequestContext.set(controller: params[:controller], action: params[:action], path: env["PATH_INFO"])
        queries    = QueryTracker.stop!
        eager_data = EagerLoadTracker.stop!
        context    = RequestContext.current
        RequestContext.clear

        unless ignored_controller?(context[:controller])
          events = (Detector.detect_n_plus_one(queries) +
                    Detector.detect_slow_queries(queries) +
                    Detector.detect_unused_eager_loads(eager_data))
                   .map { |e| e.merge(context) }
          events.each do |event|
            QueryOwl.config.notifiers.each do |notifier|
              notifier.call(event)
            rescue => e
              Rails.logger.error "[QueryOwl] Notifier #{notifier.class} raised: #{e.message}"
            end
          end
          Logger.log_summary(events)
          events.each { |e| EventStore.push(e) }
          FileLogger.append(events)
          raise_on_n_plus_one!(events) if QueryOwl.config.raise_on_n_plus_one
        end
      end
    end

    def raise_on_n_plus_one!(events)
      event = events.find { |e| e[:type] == :n_plus_one }
      return unless event

      raise NPlusOneError, "N+1 detected: #{event[:sql]} (#{event[:count]} times) #{event[:backtrace].first}"
    end

    private

      def ignored_path?(path)
        QueryOwl.config.ignore_paths.any? do |pattern|
          pattern.is_a?(Regexp) ? pattern.match?(path) : path.start_with?(pattern.to_s)
        end
      end

      def ignored_controller?(controller)
        return false unless controller

        QueryOwl.config.ignore_controllers.any? { |name| name.to_s == controller }
      end
  end
end
