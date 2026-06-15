# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Configuration API — `QueryOwl.configure` block with `enabled`, `slow_query_threshold_ms`, `n_plus_one_threshold`, and `log_level` options
- Query tracker — subscribes to `sql.active_record` notifications and accumulates queries per request using thread-local storage; ignores schema, transaction, and cached queries; captures filtered backtrace at query time
- N+1 detector — groups queries by normalized SQL (strips literals and whitespace) and flags patterns repeated at or above `n_plus_one_threshold`
- Slow query detector — flags individual queries whose duration meets or exceeds `slow_query_threshold_ms` (default: 100ms)
- Structured logger — emits `[QueryOwl] {JSON}` warning lines via `Rails.logger` at the configured log level; engine middleware wires tracker → detector → logger on every request

[Unreleased]: https://github.com/eclectic-coding/query_owl/compare/HEAD