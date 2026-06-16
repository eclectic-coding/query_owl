require "rails_helper"

RSpec.describe "query_owl:clear rake task" do
  before(:all) do
    Rails.application.load_tasks
  end

  let(:task) { Rake::Task["query_owl:clear"] }

  before do
    QueryOwl::EventStore.clear
    task.reenable
  end

  after { QueryOwl::EventStore.clear }

  it "clears all events from the event store" do
    QueryOwl::EventStore.push({ type: :slow_query, sql: "SELECT 1", duration_ms: 150 })
    QueryOwl::EventStore.push({ type: :n_plus_one, sql: "SELECT * FROM tags", count: 3 })
    expect(QueryOwl::EventStore.size).to eq(2)

    task.invoke

    expect(QueryOwl::EventStore.size).to eq(0)
  end

  it "prints a confirmation message with the event count" do
    QueryOwl::EventStore.push({ type: :slow_query, sql: "SELECT 1", duration_ms: 150 })

    expect { task.invoke }.to output(/1 event removed/).to_stdout
  end

  it "uses plural when multiple events are cleared" do
    QueryOwl::EventStore.push({ type: :slow_query, sql: "SELECT 1", duration_ms: 150 })
    QueryOwl::EventStore.push({ type: :slow_query, sql: "SELECT 2", duration_ms: 200 })

    expect { task.invoke }.to output(/2 events removed/).to_stdout
  end

  it "reports zero when the store is already empty" do
    expect { task.invoke }.to output(/0 events removed/).to_stdout
  end
end