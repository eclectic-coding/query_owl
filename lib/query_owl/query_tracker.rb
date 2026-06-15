module QueryOwl
  module QueryTracker
    IGNORED_PATTERNS = /^(SCHEMA|EXPLAIN|BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i

    class << self
      def start!
        Thread.current[:query_owl_queries] = []
      end

      def record(event)
        return unless tracking?
        return if event.payload[:name] == "SCHEMA"
        return if event.payload[:sql].to_s.match?(IGNORED_PATTERNS)

        queries << {
          sql: event.payload[:sql],
          duration_ms: event.duration.round(2),
          cached: event.payload[:cached],
          backtrace: filtered_backtrace
        }
      end

      def queries
        Thread.current[:query_owl_queries] ||= []
      end

      def stop!
        collected = queries.dup
        Thread.current[:query_owl_queries] = nil
        collected
      end

      def tracking?
        !Thread.current[:query_owl_queries].nil?
      end

      private

      def filtered_backtrace
        filter = QueryOwl.config.backtrace_filter
        lines  = QueryOwl.config.backtrace_lines
        caller.select { |line| filter.call(line) }.first(lines)
      end
    end
  end
end
