require "rails_helper"

RSpec.describe QueryOwl::Middleware do
  let(:inner_app) { ->(_env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(inner_app) }
  let(:env) { Rack::MockRequest.env_for("/") }

  after { QueryOwl.reset_config! }

  context "when enabled" do
    before { QueryOwl.config.enabled = true }

    it "calls the inner app and returns its response" do
      status, _, body = middleware.call(env)
      expect(status).to eq(200)
      expect(body).to eq(["OK"])
    end

    it "starts and stops the query tracker around the request" do
      expect(QueryOwl::QueryTracker).to receive(:start!).ordered
      expect(QueryOwl::QueryTracker).to receive(:stop!).ordered.and_return([])
      middleware.call(env)
    end

    it "runs detection and logging after the request" do
      allow(QueryOwl::QueryTracker).to receive(:stop!).and_return([])
      expect(QueryOwl::Logger).to receive(:log_events).with([])
      middleware.call(env)
    end

    it "appends events to the file logger after the request" do
      allow(QueryOwl::QueryTracker).to receive(:stop!).and_return([])
      expect(QueryOwl::FileLogger).to receive(:append).with([])
      middleware.call(env)
    end

    it "still stops the tracker if the inner app raises" do
      raising_app = ->(_env) { raise "boom" }
      m = described_class.new(raising_app)
      expect(QueryOwl::QueryTracker).to receive(:start!).ordered
      expect(QueryOwl::QueryTracker).to receive(:stop!).ordered.and_return([])
      expect { m.call(env) }.to raise_error("boom")
    end
  end

  context "when raise_on_n_plus_one is enabled" do
    before do
      QueryOwl.config.enabled = true
      QueryOwl.config.raise_on_n_plus_one = true
    end

    let(:n_plus_one_event) do
      { type: :n_plus_one, sql: "SELECT * FROM widgets WHERE id = ?", count: 3, backtrace: ["app/models/widget.rb:5"] }
    end

    it "raises NPlusOneError when an N+1 is detected" do
      allow(QueryOwl::Detector).to receive(:detect_n_plus_one).and_return([n_plus_one_event])
      allow(QueryOwl::Detector).to receive(:detect_slow_queries).and_return([])
      allow(QueryOwl::Detector).to receive(:detect_unused_eager_loads).and_return([])
      allow(QueryOwl::Logger).to receive(:log_events)
      allow(QueryOwl::Logger).to receive(:log_summary)

      expect { middleware.call(env) }.to raise_error(QueryOwl::NPlusOneError, /N\+1 detected/)
    end

    it "includes SQL and count in the error message" do
      allow(QueryOwl::Detector).to receive(:detect_n_plus_one).and_return([n_plus_one_event])
      allow(QueryOwl::Detector).to receive(:detect_slow_queries).and_return([])
      allow(QueryOwl::Detector).to receive(:detect_unused_eager_loads).and_return([])
      allow(QueryOwl::Logger).to receive(:log_events)
      allow(QueryOwl::Logger).to receive(:log_summary)

      expect { middleware.call(env) }
        .to raise_error(QueryOwl::NPlusOneError, /SELECT \* FROM widgets.*3 times/m)
    end

    it "does not raise when no N+1s are detected" do
      allow(QueryOwl::Detector).to receive(:detect_n_plus_one).and_return([])
      allow(QueryOwl::Detector).to receive(:detect_slow_queries).and_return([])
      allow(QueryOwl::Detector).to receive(:detect_unused_eager_loads).and_return([])
      allow(QueryOwl::Logger).to receive(:log_events)
      allow(QueryOwl::Logger).to receive(:log_summary)

      expect { middleware.call(env) }.not_to raise_error
    end

    it "does not raise for slow queries or unused eager loads" do
      slow = { type: :slow_query, sql: "SELECT 1", duration_ms: 200, backtrace: [] }
      allow(QueryOwl::Detector).to receive(:detect_n_plus_one).and_return([])
      allow(QueryOwl::Detector).to receive(:detect_slow_queries).and_return([slow])
      allow(QueryOwl::Detector).to receive(:detect_unused_eager_loads).and_return([])
      allow(QueryOwl::Logger).to receive(:log_events)
      allow(QueryOwl::Logger).to receive(:log_summary)

      expect { middleware.call(env) }.not_to raise_error
    end
  end

  context "request context" do
    before { QueryOwl.config.enabled = true }

    let(:slow_event) { { type: :slow_query, sql: "SELECT 1", duration_ms: 200, backtrace: [] } }

    before do
      allow(QueryOwl::Detector).to receive(:detect_n_plus_one).and_return([])
      allow(QueryOwl::Detector).to receive(:detect_slow_queries).and_return([slow_event])
      allow(QueryOwl::Detector).to receive(:detect_unused_eager_loads).and_return([])
      allow(QueryOwl::Logger).to receive(:log_events)
      allow(QueryOwl::Logger).to receive(:log_summary)
    end

    it "merges controller, action, and path into detected events" do
      routed_env = Rack::MockRequest.env_for(
        "/widgets",
        "action_dispatch.request.path_parameters" => { controller: "widgets", action: "index" }
      )

      middleware.call(routed_env)

      expect(QueryOwl::Logger).to have_received(:log_events).with([
        include(controller: "widgets", action: "index", path: "/widgets")
      ])
    end

    it "includes nil controller and action when routing params are absent" do
      middleware.call(env)

      expect(QueryOwl::Logger).to have_received(:log_events).with([
        include(controller: nil, action: nil, path: "/")
      ])
    end

    it "clears the request context after the request" do
      middleware.call(env)
      expect(QueryOwl::RequestContext.current).to eq({})
    end
  end

  context "when disabled" do
    before { QueryOwl.config.enabled = false }

    it "passes through without tracking" do
      expect(QueryOwl::QueryTracker).not_to receive(:start!)
      status, _, _ = middleware.call(env)
      expect(status).to eq(200)
    end
  end
end