# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `QueryOwl::TestHelper` — opt-in module for RSpec and Minitest; `require "query_owl/test_helper"` then `include QueryOwl::TestHelper` in your test setup
  - RSpec block matchers: `expect { }.not_to trigger_n_plus_one`, `trigger_slow_query`, `trigger_unused_eager_load`
  - Minitest assertions: `assert_no_n_plus_one { }`, `assert_no_slow_query { }`
  - Each helper runs its block with trackers active, isolated from `config.enabled` and `config.raise_on_n_plus_one`
- Opt-in setup instructions added to the install generator template

## [0.5.0] - 2026-06-16

### Added
- `query_owl:clear` Rake task — drains the in-memory `EventStore` ring buffer and prints a confirmation line with the number of events removed; useful after a deploy or investigation without restarting the server
- `config.ignore_paths` — array of path prefix strings or regexes; requests whose `PATH_INFO` matches any entry are skipped entirely in the middleware (no tracking, no events, no notifiers)
- `config.ignore_controllers` — array of controller name strings (e.g. `"rails/health"`, `"admin/metrics"`); matched after routing, trackers still stop cleanly but no events are dispatched
- Both options default to `[]`; documented with examples in the install generator template

## [0.4.1] - 2026-06-16

### Fixed
- `config.notifiers=` now validates every item at assignment time and raises `ArgumentError` if any does not respond to `#call`, surfacing misconfiguration immediately rather than producing a `NoMethodError` mid-request
- Dashboard now displays `controller`, `action`, and `path` columns; SQL column capped at 320px with ellipsis so the wider table remains readable
- Notifier errors are now rescued and logged via `Rails.logger.error` — a failing notifier can no longer crash the request or replace an already-propagating exception; remaining notifiers in the array still run
- `FileLogger` now creates missing parent directories via `FileUtils.mkdir_p` and rescues IO/permission errors with `Rails.logger.error` so a bad `log_file` path can never break the request
- `EventStore` now uses `Time.current` instead of `Time.now` for `recorded_at` timestamps, respecting the app's configured timezone

## [0.4.0] - 2026-06-16

### Added
- `rails generate query_owl:install` — generates a `config/initializers/query_owl.rb` with all nine configuration options documented and commented out by default
- `log_file` config option — when set to a file path, appends one JSON line per detected event to that file on every request; disabled by default (`nil`); useful for persisting events across server restarts
- Request context on every event — each detected event now includes `controller`, `action`, and `path` keys populated from the Rack env after routing; all consumers (logger, event store, file logger) receive the enriched hash automatically
- Custom notifier API — `config.notifiers` accepts an array of any objects responding to `#call(event)`; built-in `QueryOwl::Notifiers::Logger` (default, writes to `Rails.logger`) and `QueryOwl::Notifiers::Stdout` (writes to `$stdout`, useful for background jobs and Rake tasks)
- `QueryOwl::Notifiers::Console` — TTY-aware colorized notifier; writes directly to `$stdout` with yellow for N+1s and red for slow queries; falls back to plain output when not a TTY (piped output, CI)

## [0.3.0] - 2026-06-15

### Added
- `EventStore` — thread-safe fixed-size ring buffer that retains the last N detected events across requests; configurable via `config.event_store_size` (default: `100`); each stored event receives a `:recorded_at` timestamp; oldest events are dropped when the buffer is full
- `GET /slow_queries` JSON endpoint — returns all events from the ring buffer as a JSON array; supports `?type=`, `?controller=`, and `?action=` query params for filtering; mount the engine to enable: `mount QueryOwl::Engine => "/rails"` in your host app's routes
- HTML dashboard view at `GET /slow_queries` — tabular display of detected events (newest first) with type badges, SQL, duration/count, timestamp, and backtrace; toggled via `config.dashboard_enabled` (default: `true` in development); CSS served via modular partials inlined at render time with no asset pipeline dependency

## [0.2.0] - 2026-06-15

### Added
- Unused eager load detection — tracks associations preloaded via `includes`/`eager_load` and flags any not accessed in user code during the request; emits `:unused_eager_load` JSON events via `Rails.logger`
- `EagerLoadTracker` — thread-local tracker that records preloaded associations (via `Preloader#initialize` prepend) and user-code accesses (via `ActiveRecord::Base#association` prepend); guards against Rails' internal association wiring being counted as access by wrapping `Preloader#call`
- `backtrace_lines` config option — controls how many backtrace frames are captured per query (default: `5`)
- `backtrace_filter` config option — accepts a callable (proc/lambda) that receives each backtrace line and returns `true` to keep it; defaults to stripping gem paths and `lib/query_owl/` internals, leaving only app code
- Per-request summary line — emitted once at the end of each request when at least one issue was detected; format: `[QueryOwl] Request complete — 3 N+1s, 1 slow query, 2 unused eager loads`
- `raise_on_n_plus_one` config option (default: `false`) — raises `QueryOwl::NPlusOneError` instead of logging when an N+1 is detected; intended for CI test suites where silent warnings are easy to miss
- Improved SQL normalization — now covers float literals, bare UUIDs, PostgreSQL bind parameters (`$1`/`$2`), IN-list collapsing (`IN (1,2,3)` → `IN (?)`), and double-quote/backtick identifier stripping so queries from different adapters group correctly

## [0.1.0] - 2026-06-15

### Added
- Configuration API — `QueryOwl.configure` block with `enabled`, `slow_query_threshold_ms`, `n_plus_one_threshold`, and `log_level` options
- Query tracker — subscribes to `sql.active_record` notifications and accumulates queries per request using thread-local storage; ignores schema, transaction, and cached queries; captures filtered backtrace at query time
- N+1 detector — groups queries by normalized SQL (strips literals and whitespace) and flags patterns repeated at or above `n_plus_one_threshold`
- Slow query detector — flags individual queries whose duration meets or exceeds `slow_query_threshold_ms` (default: 100ms)
- Structured logger — emits `[QueryOwl] {JSON}` warning lines via `Rails.logger` at the configured log level; `QueryOwl::Middleware` wires tracker → detector → logger on every request

[Unreleased]: https://github.com/eclectic-coding/query_owl/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.5.0
[0.4.1]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.4.1
[0.4.0]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.4.0
[0.3.0]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.3.0
[0.2.0]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.1.0
