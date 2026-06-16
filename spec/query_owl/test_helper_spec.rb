require "rails_helper"
require "query_owl/test_helper"

RSpec.describe QueryOwl::TestHelper do
  # Minitest-like context for testing the assert_* methods
  let(:minitest_ctx) do
    Object.new.tap do |o|
      o.extend(QueryOwl::TestHelper)
      def o.assert(condition, msg = nil)
        raise msg || "Assertion failed" unless condition
      end
    end
  end

  describe ".capture_events" do
    it "returns an empty array when no queries are made" do
      events = described_class.capture_events { }
      expect(events).to eq([])
    end

    it "returns detected events produced inside the block" do
      allow(QueryOwl::Detector).to receive(:detect_n_plus_one).and_return(
        [{ type: :n_plus_one, sql: "SELECT * FROM tags WHERE id = ?", count: 3, backtrace: [] }]
      )
      allow(QueryOwl::Detector).to receive(:detect_slow_queries).and_return([])
      allow(QueryOwl::Detector).to receive(:detect_unused_eager_loads).and_return([])

      events = described_class.capture_events { }
      expect(events).to include(include(type: :n_plus_one))
    end

    it "starts and stops both trackers around the block" do
      expect(QueryOwl::QueryTracker).to receive(:start!).ordered
      expect(QueryOwl::EagerLoadTracker).to receive(:start!).ordered
      expect(QueryOwl::QueryTracker).to receive(:stop!).ordered.and_return([])
      expect(QueryOwl::EagerLoadTracker).to receive(:stop!).ordered.and_return({})

      described_class.capture_events { }
    end

    it "stops the trackers and re-raises when the block raises" do
      expect(QueryOwl::QueryTracker).to receive(:stop!)
      expect(QueryOwl::EagerLoadTracker).to receive(:stop!)

      expect { described_class.capture_events { raise "boom" } }.to raise_error("boom")
    end

    it "is isolated from config.enabled" do
      QueryOwl.config.enabled = false
      expect(QueryOwl::QueryTracker).to receive(:start!)
      allow(QueryOwl::QueryTracker).to receive(:stop!).and_return([])

      described_class.capture_events { }
    ensure
      QueryOwl.reset_config!
    end
  end

  describe "#trigger_n_plus_one" do
    include QueryOwl::TestHelper

    it "returns an EventTypeMatcher for :n_plus_one" do
      expect(trigger_n_plus_one).to be_a(QueryOwl::TestHelper::EventTypeMatcher)
    end

    it "matches when an N+1 is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return(
        [{ type: :n_plus_one, sql: "SELECT...", count: 3, backtrace: [] }]
      )
      expect { }.to trigger_n_plus_one
    end

    it "does not match when no N+1 is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return([])
      expect { }.not_to trigger_n_plus_one
    end
  end

  describe "#trigger_slow_query" do
    include QueryOwl::TestHelper

    it "matches when a slow query is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return(
        [{ type: :slow_query, sql: "SELECT 1", duration_ms: 300, backtrace: [] }]
      )
      expect { }.to trigger_slow_query
    end

    it "does not match when no slow query is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return([])
      expect { }.not_to trigger_slow_query
    end
  end

  describe "#trigger_unused_eager_load" do
    include QueryOwl::TestHelper

    it "matches when an unused eager load is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return(
        [{ type: :unused_eager_load, association: "tags", backtrace: [] }]
      )
      expect { }.to trigger_unused_eager_load
    end

    it "does not match when no unused eager load is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return([])
      expect { }.not_to trigger_unused_eager_load
    end
  end

  describe "#assert_no_n_plus_one" do
    it "passes when no N+1 is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return([])
      expect { minitest_ctx.assert_no_n_plus_one { } }.not_to raise_error
    end

    it "raises with a descriptive message when N+1s are detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return(
        [{ type: :n_plus_one }, { type: :n_plus_one }]
      )
      expect { minitest_ctx.assert_no_n_plus_one { } }
        .to raise_error(/Expected no N\+1 queries, but 2 detected/)
    end

    it "accepts a custom failure message" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return(
        [{ type: :n_plus_one }]
      )
      expect { minitest_ctx.assert_no_n_plus_one("N+1 found in widget load") { } }
        .to raise_error("N+1 found in widget load")
    end
  end

  describe "#assert_no_slow_query" do
    it "passes when no slow query is detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return([])
      expect { minitest_ctx.assert_no_slow_query { } }.not_to raise_error
    end

    it "raises with a descriptive message when slow queries are detected" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return(
        [{ type: :slow_query }]
      )
      expect { minitest_ctx.assert_no_slow_query { } }
        .to raise_error(/Expected no slow queries, but 1 detected/)
    end
  end

  describe QueryOwl::TestHelper::EventTypeMatcher do
    let(:matcher) { described_class.new(:n_plus_one) }

    it "supports block expectations" do
      expect(matcher.supports_block_expectations?).to be(true)
    end

    it "provides a failure_message when the event was expected but not found" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return([])
      matcher.matches?(-> {})
      expect(matcher.failure_message).to match(/trigger n plus one/)
    end

    it "provides a failure_message_when_negated with the event count" do
      allow(QueryOwl::TestHelper).to receive(:capture_events).and_return(
        [{ type: :n_plus_one }, { type: :n_plus_one }]
      )
      matcher.matches?(-> {})
      expect(matcher.failure_message_when_negated).to match(/2 detected/)
    end
  end
end