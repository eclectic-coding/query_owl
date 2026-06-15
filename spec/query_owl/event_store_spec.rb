require "rails_helper"

RSpec.describe QueryOwl::EventStore do
  let(:event) { { type: :n_plus_one, sql: "SELECT * FROM users WHERE id = ?", count: 3 } }

  before { described_class.clear }
  after  { described_class.clear; QueryOwl.reset_config! }

  describe ".push / .all" do
    it "stores a pushed event" do
      described_class.push(event)
      expect(described_class.all.length).to eq(1)
    end

    it "adds a recorded_at timestamp to each event" do
      described_class.push(event)
      expect(described_class.all.first[:recorded_at]).to be_a(Time)
    end

    it "does not mutate the original event hash" do
      described_class.push(event)
      expect(event).not_to have_key(:recorded_at)
    end

    it "returns events in insertion order" do
      described_class.push(event.merge(count: 1))
      described_class.push(event.merge(count: 2))
      described_class.push(event.merge(count: 3))
      expect(described_class.all.map { |e| e[:count] }).to eq([1, 2, 3])
    end
  end

  describe "ring buffer behaviour" do
    before { QueryOwl.config.event_store_size = 3 }

    it "retains up to event_store_size events" do
      5.times { |i| described_class.push(event.merge(count: i)) }
      expect(described_class.size).to eq(3)
    end

    it "drops the oldest event when full" do
      5.times { |i| described_class.push(event.merge(count: i)) }
      expect(described_class.all.map { |e| e[:count] }).to eq([2, 3, 4])
    end

    it "returns events oldest-first after wrap-around" do
      4.times { |i| described_class.push(event.merge(count: i)) }
      expect(described_class.all.first[:count]).to eq(1)
      expect(described_class.all.last[:count]).to eq(3)
    end
  end

  describe ".clear" do
    it "removes all stored events" do
      described_class.push(event)
      described_class.clear
      expect(described_class.all).to be_empty
    end

    it "resets size to zero" do
      described_class.push(event)
      described_class.clear
      expect(described_class.size).to eq(0)
    end
  end

  describe ".size" do
    it "returns 0 when empty" do
      expect(described_class.size).to eq(0)
    end

    it "returns the number of stored events" do
      3.times { described_class.push(event) }
      expect(described_class.size).to eq(3)
    end
  end

  describe "config.event_store_size" do
    it "defaults to 100" do
      expect(QueryOwl.config.event_store_size).to eq(100)
    end

    it "reinitialises the buffer when size changes" do
      described_class.push(event)
      QueryOwl.config.event_store_size = 5
      described_class.push(event)
      expect(described_class.size).to eq(1)
    end
  end

  describe "thread safety" do
    it "handles concurrent pushes without corruption" do
      threads = 10.times.map { Thread.new { described_class.push(event) } }
      threads.each(&:join)
      expect(described_class.size).to be <= QueryOwl.config.event_store_size
    end
  end
end