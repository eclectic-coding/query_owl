# ROADMAP

## 0.1.0 — Core Detection & Logging

Goal: install the gem, drop one line in an initializer, and immediately see structured warnings in development logs. No database, no UI.

- **N+1 detection** — flag when the same normalized SQL pattern executes 2+ times in a single request
- **Slow query detection** — flag any query exceeding a configurable threshold (default: 100ms)
- **Structured log output** — emit JSON-style warning lines via `Rails.logger.warn` containing:
  - `type` (`n_plus_one` | `slow_query`)
  - `sql` (normalized, no interpolated values)
  - `duration_ms` (for slow queries)
  - `count` (for N+1, how many times the pattern fired)
  - `backtrace` (filtered to app code only)
- Auto-enabled in development only; no overhead in production or test

---

## 0.2.0 — Unused Eager Load Detection & UX Polish

- Detect `includes`/`eager_load` calls that load associations never accessed during the request
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

---

## 1.0.0 — Stable Public API

- Locked public configuration interface with deprecation warnings for removed options
- Full README: usage guide, configuration reference, mount instructions, upgrade notes
- Verified compatibility with Rails 8.1.x and 8.2.x

---