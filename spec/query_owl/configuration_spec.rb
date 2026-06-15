require "rails_helper"

RSpec.describe QueryOwl::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it { expect(config.slow_query_threshold_ms).to eq(100) }
    it { expect(config.n_plus_one_threshold).to eq(2) }
    it { expect(config.log_level).to eq(:warn) }

    it "enables in development" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      expect(described_class.new.enabled).to be(true)
    end

    it "disables outside development" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
      expect(described_class.new.enabled).to be(false)
    end
  end

  describe "#log_level=" do
    it "accepts valid levels" do
      %i[debug info warn].each do |level|
        expect { config.log_level = level }.not_to raise_error
        expect(config.log_level).to eq(level)
      end
    end

    it "raises on invalid level" do
      expect { config.log_level = :error }.to raise_error(ArgumentError, /log_level must be one of/)
    end
  end
end

RSpec.describe QueryOwl do
  after { described_class.reset_config! }

  describe ".configure" do
    it "yields the config object" do
      described_class.configure do |c|
        c.slow_query_threshold_ms = 250
        c.n_plus_one_threshold = 3
        c.log_level = :info
      end

      expect(described_class.config.slow_query_threshold_ms).to eq(250)
      expect(described_class.config.n_plus_one_threshold).to eq(3)
      expect(described_class.config.log_level).to eq(:info)
    end
  end

  describe ".config" do
    it "returns the same instance on repeated calls" do
      expect(described_class.config).to be(described_class.config)
    end
  end

  describe ".reset_config!" do
    it "resets to a fresh configuration" do
      described_class.config.slow_query_threshold_ms = 999
      described_class.reset_config!
      expect(described_class.config.slow_query_threshold_ms).to eq(100)
    end
  end
end