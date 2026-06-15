# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Configuration API — `QueryOwl.configure` block with `enabled`, `slow_query_threshold_ms`, `n_plus_one_threshold`, and `log_level` options
- Query tracker — subscribes to `sql.active_record` notifications and accumulates queries per request using thread-local storage; ignores schema, transaction, and cached queries

[Unreleased]: https://github.com/eclectic-coding/query_owl/compare/HEAD