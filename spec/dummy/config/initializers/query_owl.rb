QueryOwl.configure do |config|
  config.enabled           = true
  config.dashboard_enabled = true

  # Console notifier writes colorized output to $stdout (yellow: N+1, red: slow query).
  # Logger notifier writes JSON lines to Rails.logger as usual.
  config.notifiers = [
    QueryOwl::Notifiers::Logger.new,
    QueryOwl::Notifiers::Console.new
  ]

  # Persist every detected event as a JSON line in log/query_owl.log.
  config.log_file = Rails.root.join("log/query_owl.log").to_s
end

Rails.application.config.after_initialize do
  QueryOwl::EventStore.push(
    type:       :n_plus_one,
    sql:        "SELECT * FROM tags WHERE widget_id = ?",
    count:      5,
    backtrace:  [ "app/controllers/widgets_controller.rb:12" ],
    controller: "widgets",
    action:     "index",
    path:       "/widgets"
  )

  QueryOwl::EventStore.push(
    type:        :slow_query,
    sql:         "SELECT * FROM widgets WHERE name LIKE ?",
    duration_ms: 312.4,
    backtrace:   [ "app/models/widget.rb:8" ],
    controller:  "widgets",
    action:      "index",
    path:        "/widgets"
  )

  QueryOwl::EventStore.push(
    type:       :unused_eager_load,
    model:      "Widget",
    association: "tags",
    backtrace:  [ "app/controllers/widgets_controller.rb:7" ],
    controller: "widgets",
    action:     "unused",
    path:       "/widgets/unused"
  )

  QueryOwl::EventStore.push(
    type:       :n_plus_one,
    sql:        "SELECT * FROM widgets WHERE id = ?",
    count:      3,
    backtrace:  [ "app/views/widgets/index.html.erb:5" ],
    controller: "widgets",
    action:     "show",
    path:       "/widgets/1"
  )
end