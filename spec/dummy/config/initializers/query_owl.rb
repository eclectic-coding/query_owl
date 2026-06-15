QueryOwl.configure do |config|
  config.enabled           = true
  config.dashboard_enabled = true
end

Rails.application.config.after_initialize do
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
end