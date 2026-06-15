require "rails_helper"

RSpec.describe QueryOwl::Logger do
  let(:n_plus_one_event) do
    { type: :n_plus_one, sql: "SELECT * FROM widgets WHERE id = ?", count: 3, backtrace: ["app/models/widget.rb:5"] }
  end

  let(:slow_query_event) do
    { type: :slow_query, sql: "SELECT * FROM reports", duration_ms: 350.5, backtrace: [] }
  end

  describe ".log_events" do
    it "writes each event to Rails.logger at the configured log level" do
      allow(Rails.logger).to receive(:warn)
      described_class.log_events([n_plus_one_event])
      expect(Rails.logger).to have_received(:warn).with(/\[QueryOwl\]/)
    end

    it "includes the event type in the output" do
      allow(Rails.logger).to receive(:warn)
      described_class.log_events([n_plus_one_event])
      expect(Rails.logger).to have_received(:warn).with(/"type":"n_plus_one"/)
    end

    it "includes the SQL in the output" do
      allow(Rails.logger).to receive(:warn)
      described_class.log_events([n_plus_one_event])
      expect(Rails.logger).to have_received(:warn).with(/SELECT \* FROM widgets/)
    end

    it "does nothing when events are empty" do
      allow(Rails.logger).to receive(:warn)
      described_class.log_events([])
      expect(Rails.logger).not_to have_received(:warn)
    end

    it "respects the configured log level" do
      QueryOwl.config.log_level = :info
      allow(Rails.logger).to receive(:info)
      described_class.log_events([slow_query_event])
      expect(Rails.logger).to have_received(:info).with(/\[QueryOwl\]/)
    ensure
      QueryOwl.reset_config!
    end

    it "writes one line per event" do
      allow(Rails.logger).to receive(:warn)
      described_class.log_events([n_plus_one_event, slow_query_event])
      expect(Rails.logger).to have_received(:warn).twice
    end
  end
end