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

  # Paths to skip entirely — accepts strings (prefix match) or regexes.
  # Useful for health check endpoints and other high-frequency low-value paths.
  # config.ignore_paths = ["/up", "/healthz", %r{^/assets/}]

  # Controllers to skip — matched against the Rails controller name (e.g. "rails/health").
  # config.ignore_controllers = ["rails/health", "admin/metrics"]

  # Test helper — opt-in RSpec matchers and Minitest assertions.
  # Add to spec/rails_helper.rb (or test/test_helper.rb for Minitest):
  #
  #   require "query_owl/test_helper"
  #   RSpec.configure { |c| c.include QueryOwl::TestHelper }
  #   # or: class ActiveSupport::TestCase; include QueryOwl::TestHelper; end
  #
  # Then use: expect { }.not_to trigger_n_plus_one
  #           expect { }.not_to trigger_slow_query
  #           expect { }.not_to trigger_unused_eager_load
  #           assert_no_n_plus_one { }
  #           assert_no_slow_query { }

  # Notifiers receive each detected event via #call(event).
  # Defaults to [QueryOwl::Notifiers::Logger] which writes to Rails.logger.
  # Use Console for TTY-aware colorized output (yellow: N+1, red: slow query).
  # Use Stdout for non-request contexts (jobs, Rake tasks).
  # config.notifiers = [QueryOwl::Notifiers::Console.new]
end
