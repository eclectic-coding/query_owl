# ROADMAP

## 0.2.0 — UX Polish

- Configurable backtrace depth and filtering (exclude gem paths, Rails internals)
- Per-request summary line appended at end of request (total N+1 count, slow query count)
- `raise_on_n_plus_one` config option — raises instead of logging (useful in CI test suites)
- Improved SQL normalization to better group parameterized queries across different bind values

---

## 0.3.0 — Slow Queries Dashboard

- In-memory ring buffer storing the last N detected events (configurable size, default: `100`)
- `GET /rails/slow_queries` JSON endpoint — paginated, filterable by type / controller / action / time window
- Mount the engine at `/rails` in the host app: `mount QueryOwl::Engine => "/rails"`
- Optional minimal HTML view (no Tailwind, no asset pipeline dependency)

---

## 0.4.0 — Persistence & Notifications

- File-based persistence: append structured JSON lines to a configurable log file path
- Request context on every event: controller name, action, request path (via middleware)
- Custom notifier API: `QueryOwl.config.notifiers << MyNotifier` (duck-typed, receives event hash)
- Built-in `$stdout` notifier for non-request contexts (background jobs, Rake tasks)
- Built-in `QueryOwl::Notifiers::Console` — TTY-aware colorized output written directly to `$stdout`, keeping `Rails.logger` / log files free of ANSI escape codes

---

## 1.0.0 — Stable Public API

- Locked public configuration interface with deprecation warnings for removed options
- Full README: usage guide, configuration reference, mount instructions, upgrade notes
- Verified compatibility with Rails 8.1.x and 8.2.x

---
