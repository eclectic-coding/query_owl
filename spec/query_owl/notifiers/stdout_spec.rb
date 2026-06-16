require "rails_helper"

RSpec.describe QueryOwl::Notifiers::Stdout do
  subject(:notifier) { described_class.new }

  let(:event) { { type: :slow_query, sql: "SELECT * FROM reports", duration_ms: 350.5, backtrace: [] } }

  it "writes the event to $stdout" do
    expect { notifier.call(event) }.to output(/\[QueryOwl\]/).to_stdout
  end

  it "includes the event JSON in the output" do
    expect { notifier.call(event) }.to output(/slow_query/).to_stdout
  end

  it "responds to #call" do
    expect(notifier).to respond_to(:call)
  end
end