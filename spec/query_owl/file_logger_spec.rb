require "rails_helper"

RSpec.describe QueryOwl::FileLogger do
  let(:log_path) { Tempfile.new(["query_owl_test", ".log"]).path }

  before do
    QueryOwl.configure { |c| c.log_file = log_path }
  end

  after do
    QueryOwl.reset_config!
    File.delete(log_path) if File.exist?(log_path)
  end

  describe ".append" do
    it "does nothing when events is empty" do
      described_class.append([])
      expect(File.read(log_path)).to be_empty
    end

    it "does nothing when log_file is nil" do
      QueryOwl.configure { |c| c.log_file = nil }
      described_class.append([{ type: :slow_query, sql: "SELECT 1", duration_ms: 150 }])
      expect(File.size(log_path)).to eq(0)
    end

    it "appends one JSON line per event" do
      events = [
        { type: :slow_query, sql: "SELECT 1", duration_ms: 150 },
        { type: :n_plus_one, sql: "SELECT * FROM tags WHERE widget_id = ?", count: 5 }
      ]
      described_class.append(events)
      lines = File.readlines(log_path)
      expect(lines.size).to eq(2)
    end

    it "serializes each event as valid JSON" do
      event = { type: :slow_query, sql: "SELECT 1", duration_ms: 150.3 }
      described_class.append([event])
      parsed = JSON.parse(File.read(log_path))
      expect(parsed["type"]).to eq("slow_query")
      expect(parsed["sql"]).to eq("SELECT 1")
      expect(parsed["duration_ms"]).to eq(150.3)
    end

    it "converts symbol values to strings" do
      described_class.append([{ type: :n_plus_one }])
      parsed = JSON.parse(File.read(log_path))
      expect(parsed["type"]).to eq("n_plus_one")
    end

    it "appends to an existing file rather than overwriting" do
      described_class.append([{ type: :slow_query, sql: "SELECT 1", duration_ms: 100 }])
      described_class.append([{ type: :slow_query, sql: "SELECT 2", duration_ms: 200 }])
      lines = File.readlines(log_path)
      expect(lines.size).to eq(2)
    end
  end
end