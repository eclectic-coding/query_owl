require "rails_helper"

RSpec.describe QueryOwl::Notifiers::Console do
  subject(:notifier) { described_class.new }

  let(:n_plus_one_event) { { type: :n_plus_one, sql: "SELECT * FROM widgets WHERE id = ?", count: 3, backtrace: [] } }
  let(:slow_query_event) { { type: :slow_query, sql: "SELECT * FROM reports", duration_ms: 342.1, backtrace: [] } }
  let(:unused_eager_load_event) { { type: :unused_eager_load, model: "Widget", association: "tags" } }

  context "when $stdout is not a TTY" do
    before { allow($stdout).to receive(:tty?).and_return(false) }

    it "writes N+1 events to $stdout" do
      expect { notifier.call(n_plus_one_event) }.to output(/\[QueryOwl\] n_plus_one.*×3/).to_stdout
    end

    it "writes slow query events to $stdout" do
      expect { notifier.call(slow_query_event) }.to output(/\[QueryOwl\] slow_query.*342/).to_stdout
    end

    it "writes unused eager load events to $stdout" do
      expect { notifier.call(unused_eager_load_event) }.to output(/\[QueryOwl\] unused_eager_load.*Widget#tags/).to_stdout
    end

    it "does not include ANSI escape codes" do
      expect { notifier.call(n_plus_one_event) }.not_to output(/\e\[/).to_stdout
    end
  end

  context "when $stdout is a TTY" do
    before do
      allow($stdout).to receive(:tty?).and_return(true)
      allow($stdout).to receive(:puts)
    end

    it "wraps N+1 events in yellow" do
      notifier.call(n_plus_one_event)
      expect($stdout).to have_received(:puts).with(/\e\[33m.*\e\[0m/m)
    end

    it "wraps slow query events in red" do
      notifier.call(slow_query_event)
      expect($stdout).to have_received(:puts).with(/\e\[31m.*\e\[0m/m)
    end

    it "does not colorize unused eager load events" do
      notifier.call(unused_eager_load_event)
      expect($stdout).to have_received(:puts).with(->(text) { !text.match?(/\e\[3[13]m/) })
    end
  end

  it "handles unknown event types without raising" do
    unknown = { type: :custom_event }
    expect { notifier.call(unknown) }.to output(/\[QueryOwl\] custom_event/).to_stdout
  end

  it "responds to #call" do
    expect(notifier).to respond_to(:call)
  end
end