require "rails_helper"

RSpec.describe QueryOwl::RequestContext do
  after { described_class.clear }

  describe ".set / .current" do
    it "stores controller, action, and path in thread-local storage" do
      described_class.set(controller: "widgets", action: "index", path: "/widgets")
      expect(described_class.current).to eq(controller: "widgets", action: "index", path: "/widgets")
    end
  end

  describe ".current" do
    it "returns an empty hash when no context has been set" do
      expect(described_class.current).to eq({})
    end
  end

  describe ".clear" do
    it "removes the stored context" do
      described_class.set(controller: "widgets", action: "index", path: "/widgets")
      described_class.clear
      expect(described_class.current).to eq({})
    end
  end

  describe "thread isolation" do
    it "does not share context between threads" do
      described_class.set(controller: "main", action: "index", path: "/")

      other_context = nil
      Thread.new { other_context = described_class.current }.join

      expect(other_context).to eq({})
    end
  end
end