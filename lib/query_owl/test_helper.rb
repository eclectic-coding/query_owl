require "query_owl"

module QueryOwl
  module TestHelper
    # Runs block with QueryOwl's trackers active and returns detected events.
    # Isolated from config.enabled and config.raise_on_n_plus_one.
    def self.capture_events
      QueryTracker.start!
      EagerLoadTracker.start!
      yield
      queries    = QueryTracker.stop!
      eager_data = EagerLoadTracker.stop!
      Detector.detect_n_plus_one(queries) +
        Detector.detect_slow_queries(queries) +
        Detector.detect_unused_eager_loads(eager_data)
    rescue
      QueryTracker.stop!
      EagerLoadTracker.stop!
      raise
    end

    # RSpec block matchers — use with expect { }.to / not_to

    def trigger_n_plus_one
      EventTypeMatcher.new(:n_plus_one)
    end

    def trigger_slow_query
      EventTypeMatcher.new(:slow_query)
    end

    def trigger_unused_eager_load
      EventTypeMatcher.new(:unused_eager_load)
    end

    # Minitest assertions — call assert_no_n_plus_one { } inside a test method

    def assert_no_n_plus_one(msg = nil, &block)
      events = QueryOwl::TestHelper.capture_events(&block)
      count  = events.count { |e| e[:type] == :n_plus_one }
      assert count.zero?, msg || "Expected no N+1 queries, but #{count} detected"
    end

    def assert_no_slow_query(msg = nil, &block)
      events = QueryOwl::TestHelper.capture_events(&block)
      count  = events.count { |e| e[:type] == :slow_query }
      assert count.zero?, msg || "Expected no slow queries, but #{count} detected"
    end

    class EventTypeMatcher
      def initialize(type)
        @type   = type
        @events = []
      end

      def matches?(block)
        @events = QueryOwl::TestHelper.capture_events(&block)
        @events.any? { |e| e[:type] == @type }
      end

      def does_not_match?(block)
        !matches?(block)
      end

      def supports_block_expectations?
        true
      end

      def failure_message
        "expected block to trigger #{label} but none were detected"
      end

      def failure_message_when_negated
        n = @events.count { |e| e[:type] == @type }
        "expected block not to trigger #{label} but #{n} detected"
      end

      private

        def label
          @type.to_s.tr("_", " ")
        end
    end
  end
end
