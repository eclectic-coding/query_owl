widgets = [
  { name: "Alpha",   tags: %w[ruby rails] },
  { name: "Beta",    tags: %w[performance] },
  { name: "Gamma",   tags: %w[ruby api json] },
  { name: "Delta",   tags: [] },
  { name: "Epsilon", tags: %w[slow expensive] }
]

widgets.each do |attrs|
  widget = Widget.find_or_create_by!(name: attrs[:name])
  attrs[:tags].each { |t| widget.tags.find_or_create_by!(name: t) }
end

puts "Seeded #{Widget.count} widgets and #{Tag.count} tags."

# Seed the EventStore with representative events for dashboard testing.
QueryOwl::EventStore.clear

QueryOwl::EventStore.push(
  type: :n_plus_one,
  sql: "SELECT * FROM tags WHERE widget_id = ?",
  count: 5,
  backtrace: ["app/controllers/widgets_controller.rb:12"]
)

QueryOwl::EventStore.push(
  type: :slow_query,
  sql: "SELECT * FROM widgets WHERE name LIKE ?",
  duration_ms: 312.4,
  backtrace: ["app/models/widget.rb:8"]
)

QueryOwl::EventStore.push(
  type: :unused_eager_load,
  model: "Widget",
  association: "tags",
  backtrace: ["app/controllers/widgets_controller.rb:7"]
)

QueryOwl::EventStore.push(
  type: :n_plus_one,
  sql: "SELECT * FROM widgets WHERE id = ?",
  count: 3,
  backtrace: ["app/views/widgets/index.html.erb:5"]
)

puts "Seeded #{QueryOwl::EventStore.size} events into EventStore."