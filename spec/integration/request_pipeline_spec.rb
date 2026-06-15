require "rails_helper"

RSpec.describe "QueryOwl request pipeline" do
  before do
    QueryOwl.config.enabled = true
    Widget.create!(name: "Alpha")
    Widget.create!(name: "Beta")
    Widget.create!(name: "Gamma")
  end

  after { QueryOwl.reset_config! }

  def simulate_request
    QueryOwl::QueryTracker.start!
    yield
  ensure
    queries = QueryOwl::QueryTracker.stop!
    events  = QueryOwl::Detector.detect_n_plus_one(queries) +
              QueryOwl::Detector.detect_slow_queries(queries)
    QueryOwl::Logger.log_events(events)
  end

  describe "N+1 detection" do
    it "logs a warning when the same query fires multiple times" do
      allow(Rails.logger).to receive(:warn)

      simulate_request do
        Widget.find(1) rescue nil
        Widget.find(2) rescue nil
        Widget.find(3) rescue nil
      end

      expect(Rails.logger).to have_received(:warn).with(/n_plus_one/)
    end

    it "does not log when queries are unique" do
      allow(Rails.logger).to receive(:warn)

      simulate_request { Widget.all.to_a }

      expect(Rails.logger).not_to have_received(:warn)
    end
  end

  describe "slow query detection" do
    it "logs a warning when slow_query_threshold_ms is set very low" do
      QueryOwl.config.slow_query_threshold_ms = 0
      allow(Rails.logger).to receive(:warn)

      simulate_request { Widget.all.to_a }

      expect(Rails.logger).to have_received(:warn).with(/slow_query/)
    end
  end
end