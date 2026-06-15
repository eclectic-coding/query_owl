require "rails_helper"

RSpec.describe "Unused eager load detection" do
  before do
    QueryOwl.config.enabled = true
    widget = Widget.create!(name: "Alpha")
    widget.tags.create!(name: "ruby")
  end

  after { QueryOwl.reset_config! }

  def simulate_request
    QueryOwl::QueryTracker.start!
    QueryOwl::EagerLoadTracker.start!
    yield
  ensure
    queries    = QueryOwl::QueryTracker.stop!
    eager_data = QueryOwl::EagerLoadTracker.stop!
    events     = QueryOwl::Detector.detect_n_plus_one(queries) +
                 QueryOwl::Detector.detect_slow_queries(queries) +
                 QueryOwl::Detector.detect_unused_eager_loads(eager_data)
    QueryOwl::Logger.log_events(events)
  end

  it "logs a warning when an eager-loaded association is never accessed" do
    allow(Rails.logger).to receive(:warn)

    simulate_request do
      widgets = Widget.includes(:tags).to_a
      widgets.map(&:name)
    end

    expect(Rails.logger).to have_received(:warn).with(/unused_eager_load/)
  end

  it "does not log when the eager-loaded association is accessed" do
    allow(Rails.logger).to receive(:warn)

    simulate_request do
      widgets = Widget.includes(:tags).to_a
      widgets.each { |w| w.tags.to_a }
    end

    expect(Rails.logger).not_to have_received(:warn).with(/unused_eager_load/)
  end
end