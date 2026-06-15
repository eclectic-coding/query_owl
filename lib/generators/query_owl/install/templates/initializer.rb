QueryOwl.configure do |config|
  # Enable or disable all QueryOwl tracking.
  # Defaults to true in development, false elsewhere.
  # config.enabled = Rails.env.development?

  # Flag N+1 queries when the same SQL pattern fires this many times per request.
  # config.n_plus_one_threshold = 2

  # Flag individual queries that take longer than this (in milliseconds).
  # config.slow_query_threshold_ms = 100

  # Log level for QueryOwl warnings (:debug, :info, or :warn).
  # config.log_level = :warn

  # Number of backtrace frames captured per query.
  # config.backtrace_lines = 5

  # Custom backtrace filter — a callable that receives a line and returns true to keep it.
  # Defaults to stripping gem paths and QueryOwl internals.
  # config.backtrace_filter = ->(line) { line.start_with?("app/") }

  # Raise QueryOwl::NPlusOneError instead of logging when an N+1 is detected.
  # Useful in CI test suites where silent warnings are easy to miss.
  # config.raise_on_n_plus_one = false

  # Maximum number of events retained in the in-memory ring buffer.
  # config.event_store_size = 100

  # Enable the HTML dashboard at GET /slow_queries (when the engine is mounted).
  # Defaults to true in development, false elsewhere.
  # config.dashboard_enabled = Rails.env.development?

  # Append each detected event as a JSON line to this file path.
  # Disabled by default (nil). Useful for persistence across restarts.
  # config.log_file = Rails.root.join("log/query_owl.log").to_s
end
