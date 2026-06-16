require "query_owl"

module QueryOwl
  # Provides test helpers for RSpec and Minitest.
  #
  # Include this module in your test configuration:
  #
  # @example RSpec
  #   RSpec.configure do |config|
  #     config.include QueryOwl::TestHelper
  #   end
  #
  # @example Minitest
  #   class ActiveSupport::TestCase
  #     include QueryOwl::TestHelper
  #   end
  module TestHelper
    # Runs a block with QueryOwl's trackers active and returns all detected events.
    # Isolated from {Configuration#enabled} and {Configuration#raise_on_n_plus_one}.
    #
    # @yield block of code to instrument
    # @return [Array<Hash>] detected events, each with at minimum a +:type+ key
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

    # RSpec block matcher — asserts that the block triggers at least one N+1 event.
    #
    # @return [EventTypeMatcher]
    # @example
    #   expect { Post.all.each(&:author) }.to trigger_n_plus_one
    def trigger_n_plus_one
      EventTypeMatcher.new(:n_plus_one)
    end

    # RSpec block matcher — asserts that the block triggers at least one slow query event.
    #
    # @return [EventTypeMatcher]
    # @example
    #   expect { Post.with_heavy_scope.load }.to trigger_slow_query
    def trigger_slow_query
      EventTypeMatcher.new(:slow_query)
    end

    # RSpec block matcher — asserts that the block triggers at least one unused eager load event.
    #
    # @return [EventTypeMatcher]
    # @example
    #   expect { Post.includes(:comments).each(&:title) }.to trigger_unused_eager_load
    def trigger_unused_eager_load
      EventTypeMatcher.new(:unused_eager_load)
    end

    # Minitest assertion — fails if any N+1 queries are detected within the block.
    #
    # @param msg [String, nil] custom failure message
    # @yield block of code to instrument
    def assert_no_n_plus_one(msg = nil, &block)
      events = QueryOwl::TestHelper.capture_events(&block)
      count  = events.count { |e| e[:type] == :n_plus_one }
      assert count.zero?, msg || "Expected no N+1 queries, but #{count} detected"
    end

    # Minitest assertion — fails if any slow queries are detected within the block.
    #
    # @param msg [String, nil] custom failure message
    # @yield block of code to instrument
    def assert_no_slow_query(msg = nil, &block)
      events = QueryOwl::TestHelper.capture_events(&block)
      count  = events.count { |e| e[:type] == :slow_query }
      assert count.zero?, msg || "Expected no slow queries, but #{count} detected"
    end

    # RSpec custom matcher that checks for a specific event type in the block.
    class EventTypeMatcher
      # @param type [Symbol] one of +:n_plus_one+, +:slow_query+, +:unused_eager_load+
      def initialize(type)
        @type   = type
        @events = []
      end

      # @param block [Proc]
      # @return [Boolean]
      def matches?(block)
        @events = QueryOwl::TestHelper.capture_events(&block)
        @events.any? { |e| e[:type] == @type }
      end

      # @param block [Proc]
      # @return [Boolean]
      def does_not_match?(block)
        !matches?(block)
      end

      # @return [Boolean]
      def supports_block_expectations?
        true
      end

      # @return [String]
      def failure_message
        "expected block to trigger #{label} but none were detected"
      end

      # @return [String]
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
