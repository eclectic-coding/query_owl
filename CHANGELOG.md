# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `EventStore` — thread-safe fixed-size ring buffer that retains the last N detected events across requests; configurable via `config.event_store_size` (default: `100`); each stored event receives a `:recorded_at` timestamp; oldest events are dropped when the buffer is full
- `GET /slow_queries` JSON endpoint — returns all events from the ring buffer as a JSON array; supports `?type=`, `?controller=`, and `?action=` query params for filtering; mount the engine to enable: `mount QueryOwl::Engine => "/rails"` in your host app's routes

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

[Unreleased]: https://github.com/eclectic-coding/query_owl/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/query_owl/releases/tag/v0.1.0
