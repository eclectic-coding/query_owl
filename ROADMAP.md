# ROADMAP

## 0.4.1 — Resilience & Correctness

- Use `Time.current` instead of `Time.now` in `EventStore` so `recorded_at` respects the app's configured timezone
- Validate `config.notifiers=` setter — raise `ArgumentError` if any item does not respond to `#call`

---

## 0.5.0 — Developer Experience

- Ignore list — `config.ignore_controllers` and `config.ignore_paths` arrays to suppress tracking for health checks, admin endpoints, etc.
- `query_owl:clear` Rake task — drain the in-memory `EventStore` from the console or a deploy script

---

## 0.6.0 — Test Support

- `QueryOwl::TestHelper` — opt-in module providing RSpec matchers and Minitest assertions (e.g. `expect { }.not_to trigger_n_plus_one`) for use in integration test suites

---

## 1.0.0 — Stable Public API

- Locked public configuration interface with deprecation warnings for removed options
- Full README: usage guide, configuration reference, mount instructions, upgrade notes, links to ROADMAP and CONTRIBUTING
- `CONTRIBUTING.md`: setup instructions, test suite guide, PR and commit conventions, bug reporting
- Verified compatibility with Rails 8.1.x and 8.2.x

---