require "rails_helper"

RSpec.describe QueryOwl::Notifiers::Logger do
  subject(:notifier) { described_class.new }

  let(:event) { { type: :n_plus_one, sql: "SELECT * FROM widgets WHERE id = ?", count: 3, backtrace: [] } }

  after { QueryOwl.reset_config! }

  it "writes the event to Rails.logger at the configured log level" do
    allow(Rails.logger).to receive(:warn)
    notifier.call(event)
    expect(Rails.logger).to have_received(:warn).with(/\[QueryOwl\]/)
  end

  it "includes the event JSON in the output" do
    allow(Rails.logger).to receive(:warn)
    notifier.call(event)
    expect(Rails.logger).to have_received(:warn).with(/n_plus_one/)
  end

  it "respects the configured log level" do
    QueryOwl.config.log_level = :info
    allow(Rails.logger).to receive(:info)
    notifier.call(event)
    expect(Rails.logger).to have_received(:info).with(/\[QueryOwl\]/)
  end

  it "responds to #call" do
    expect(notifier).to respond_to(:call)
  end
end