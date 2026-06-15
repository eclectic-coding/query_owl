require "rails_helper"

RSpec.describe QueryOwl::EagerLoadTracker do
  before { described_class.start! }
  after  { described_class.stop! }

  describe ".start! / .tracking?" do
    it "marks the tracker as active" do
      expect(described_class.tracking?).to be(true)
    end
  end

  describe ".record_preload" do
    it "records a preloaded association" do
      described_class.record_preload("User", :posts)
      data = described_class.stop!
      expect(data[:preloaded]).to include({ model: "User", association: "posts" })
    end

    it "does nothing when not tracking" do
      described_class.stop!
      described_class.record_preload("User", :posts)
      # no error, no state mutation
      expect(described_class.tracking?).to be(false)
    end
  end

  describe ".record_access" do
    it "records an accessed association" do
      described_class.record_access("User", :posts)
      data = described_class.stop!
      expect(data[:accessed]).to include("User#posts")
    end
  end

  describe ".stop!" do
    it "returns preloaded and accessed data" do
      described_class.record_preload("User", :posts)
      described_class.record_access("User", :posts)
      data = described_class.stop!
      expect(data.keys).to contain_exactly(:preloaded, :accessed)
    end

    it "clears thread-local state" do
      described_class.stop!
      expect(described_class.tracking?).to be(false)
    end
  end
end