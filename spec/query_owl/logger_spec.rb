require "rails_helper"

RSpec.describe QueryOwl::Logger do
  let(:n_plus_one_event) do
    { type: :n_plus_one, sql: "SELECT * FROM widgets WHERE id = ?", count: 3, backtrace: ["app/models/widget.rb:5"] }
  end

  let(:slow_query_event) do
    { type: :slow_query, sql: "SELECT * FROM reports", duration_ms: 350.5, backtrace: [] }
  end

  let(:unused_eager_load_event) do
    { type: :unused_eager_load, model: "Widget", association: "tags" }
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

  describe ".log_summary" do
    before { allow(Rails.logger).to receive(:warn) }

    it "does nothing when events are empty" do
      described_class.log_summary([])
      expect(Rails.logger).not_to have_received(:warn)
    end

    it "emits a single summary line" do
      described_class.log_summary([n_plus_one_event])
      expect(Rails.logger).to have_received(:warn).once
    end

    it "includes the QueryOwl prefix" do
      described_class.log_summary([n_plus_one_event])
      expect(Rails.logger).to have_received(:warn).with(/\[QueryOwl\] Request complete/)
    end

    it "pluralises N+1s correctly" do
      described_class.log_summary([n_plus_one_event, n_plus_one_event])
      expect(Rails.logger).to have_received(:warn).with(/2 N\+1s/)
    end

    it "uses singular for a single N+1" do
      described_class.log_summary([n_plus_one_event])
      expect(Rails.logger).to have_received(:warn).with(/1 N\+1(?!s)/)
    end

    it "pluralises slow queries correctly" do
      described_class.log_summary([slow_query_event, slow_query_event])
      expect(Rails.logger).to have_received(:warn).with(/2 slow queries/)
    end

    it "uses singular for a single slow query" do
      described_class.log_summary([slow_query_event])
      expect(Rails.logger).to have_received(:warn).with(/1 slow query/)
    end

    it "pluralises unused eager loads correctly" do
      described_class.log_summary([unused_eager_load_event, unused_eager_load_event])
      expect(Rails.logger).to have_received(:warn).with(/2 unused eager loads/)
    end

    it "uses singular for a single unused eager load" do
      described_class.log_summary([unused_eager_load_event])
      expect(Rails.logger).to have_received(:warn).with(/1 unused eager load(?!s)/)
    end

    it "includes all event types in the summary" do
      described_class.log_summary([n_plus_one_event, slow_query_event, unused_eager_load_event])
      expect(Rails.logger).to have_received(:warn).with(/N\+1.*slow query.*unused eager load/m)
    end

    it "omits zero-count types" do
      described_class.log_summary([n_plus_one_event])
      expect(Rails.logger).not_to have_received(:warn).with(/slow quer/)
    end

    it "respects the configured log level" do
      QueryOwl.config.log_level = :info
      allow(Rails.logger).to receive(:info)
      described_class.log_summary([n_plus_one_event])
      expect(Rails.logger).to have_received(:info).with(/Request complete/)
    ensure
      QueryOwl.reset_config!
    end
  end
end