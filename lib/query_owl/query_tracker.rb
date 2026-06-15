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
        caller.grep_v(%r{/gems/|/rubygems/|/ruby/gems/|lib/query_owl/}).first(5)
      end
    end
  end
end
