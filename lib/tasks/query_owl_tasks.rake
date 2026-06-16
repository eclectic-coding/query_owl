namespace :query_owl do
  desc "Clear all events from the QueryOwl in-memory event store"
  task clear: :environment do
    count = QueryOwl::EventStore.size
    QueryOwl::EventStore.clear
    puts "[QueryOwl] Event store cleared (#{count} event#{"s" if count != 1} removed)."
  end
end
