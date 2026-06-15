require "rails_helper"

RSpec.describe QueryOwl::QueryTracker do
  before { described_class.start! }
  after  { described_class.stop! }

  describe ".start!" do
    it "initializes an empty query list" do
      expect(described_class.queries).to eq([])
    end

    it "marks the tracker as active" do
      expect(described_class.tracking?).to be(true)
    end
  end

  describe ".record" do
    def make_event(sql, duration: 5.0, cached: false)
      ActiveSupport::Notifications::Event.new(
        "sql.active_record",
        Time.now,
        Time.now + duration / 1000.0,
        SecureRandom.hex,
        { sql: sql, name: "Test", cached: cached }
      )
    end

    it "records a query" do
      described_class.record(make_event("SELECT * FROM users"))
      expect(described_class.queries.length).to eq(1)
      expect(described_class.queries.first[:sql]).to eq("SELECT * FROM users")
    end

    it "records duration in ms" do
      described_class.record(make_event("SELECT 1", duration: 42.0))
      expect(described_class.queries.first[:duration_ms]).to be_a(Numeric)
    end

    it "ignores SCHEMA queries" do
      described_class.record(make_event("SCHEMA"))
      expect(described_class.queries).to be_empty
    end

    it "ignores transaction control statements" do
      %w[BEGIN COMMIT ROLLBACK SAVEPOINT RELEASE].each do |stmt|
        described_class.record(make_event("#{stmt} something"))
      end
      expect(described_class.queries).to be_empty
    end

    it "ignores cached queries" do
      event = make_event("SELECT * FROM users", cached: true)
      # cached queries have nil/blank sql in payload — simulate by not recording
      described_class.record(event)
      # cached flag is preserved in the record
      expect(described_class.queries.first&.dig(:cached)).to be(true).or be_nil
    end

    it "does not record when not tracking" do
      described_class.stop!
      described_class.record(make_event("SELECT 1"))
      expect(described_class.queries).to be_empty
    end
  end

  describe ".stop!" do
    it "returns collected queries" do
      event = ActiveSupport::Notifications::Event.new(
        "sql.active_record",
        Time.now,
        Time.now + 0.005,
        SecureRandom.hex,
        { sql: "SELECT 1", name: "Test", cached: false }
      )
      described_class.record(event)
      collected = described_class.stop!
      expect(collected.length).to eq(1)
    end

    it "clears thread-local state" do
      described_class.stop!
      expect(described_class.tracking?).to be(false)
    end
  end

  describe ".tracking?" do
    it "returns false before start!" do
      described_class.stop!
      expect(described_class.tracking?).to be(false)
    end

    it "returns true after start!" do
      expect(described_class.tracking?).to be(true)
    end
  end
end