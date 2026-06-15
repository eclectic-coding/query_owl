# QueryOwl

[![CI](https://github.com/eclectic-coding/query_owl/actions/workflows/main.yml/badge.svg)](https://github.com/eclectic-coding/query_owl/actions/workflows/main.yml)
[![Gem Version](https://img.shields.io/gem/v/query_owl)](https://rubygems.org/gems/query_owl)
[![Downloads](https://img.shields.io/gem/dt/query_owl)](https://rubygems.org/gems/query_owl)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-ruby)](https://www.ruby-lang.org)
[![codecov](https://codecov.io/gh/eclectic-coding/query_owl/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/query_owl)

A leaner alternative to Bullet. QueryOwl detects N+1 queries, slow queries, and unused eager loads in development, logging structured warnings to your Rails logger — without the noise.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Log Output](#log-output)
- [Dashboard Endpoint](#dashboard-endpoint)
- [Manual Testing in the Dummy App](#manual-testing-in-the-dummy-app)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **N+1 detection** — flags when the same SQL pattern fires 2+ times in a single request
- **Slow query detection** — flags queries exceeding a configurable threshold (default: 100ms)
- **Unused eager load detection** — flags associations preloaded via `includes`/`eager_load` that are never accessed during the request
- **Per-request summary** — single summary line at the end of each request with totals (e.g. `Request complete — 3 N+1s, 1 slow query`)
- **CI-friendly raise mode** — set `raise_on_n_plus_one: true` to raise `QueryOwl::NPlusOneError` instead of logging, making N+1s fail fast in test suites
- **Structured log output** — JSON-style warnings via `Rails.logger` with SQL, duration, count, and filtered backtrace
- **Zero overhead in production** — auto-enabled in development only

[↑ Back to top](#table-of-contents)

---

## Installation

Add to your `Gemfile`:

```ruby
gem "query_owl"
```

Then run:

```sh
bundle install
```

[↑ Back to top](#table-of-contents)

---

## Configuration

Create an initializer:

```ruby
# config/initializers/query_owl.rb
QueryOwl.configure do |config|
  config.enabled                 = Rails.env.development?
  config.slow_query_threshold_ms = 100   # flag queries slower than this
  config.n_plus_one_threshold    = 2     # flag after this many repeated patterns
  config.log_level               = :warn # :warn | :info | :debug
  config.backtrace_lines         = 5     # number of backtrace frames to capture
  config.backtrace_filter        = ->(line) { line.start_with?("app/") } # optional custom filter
  config.raise_on_n_plus_one     = false # set true in CI to raise instead of log
end
```

[↑ Back to top](#table-of-contents)

---

## Log Output

When a problem is detected, QueryOwl writes a structured line to `Rails.logger`:

```
[QueryOwl] {"type":"n_plus_one","sql":"SELECT * FROM posts WHERE user_id = ?","count":10,"backtrace":["app/controllers/posts_controller.rb:12"]}
[QueryOwl] {"type":"slow_query","sql":"SELECT * FROM reports WHERE ...","duration_ms":340}
[QueryOwl] {"type":"unused_eager_load","model":"Widget","association":"tags"}
[QueryOwl] Request complete — 10 N+1s, 1 slow query, 1 unused eager load
```

[↑ Back to top](#table-of-contents)

---

## Dashboard Endpoint

Mount the engine in your host app's routes to enable the JSON endpoint:

```ruby
# config/routes.rb
mount QueryOwl::Engine => "/rails"
```

Then query detected events at `GET /rails/slow_queries`:

```
GET /rails/slow_queries
GET /rails/slow_queries?type=n_plus_one
GET /rails/slow_queries?type=slow_query
GET /rails/slow_queries?type=unused_eager_load
```

Response is a JSON array of event objects, oldest first, up to `config.event_store_size` entries:

```json
[
  {
    "type": "n_plus_one",
    "sql": "SELECT * FROM posts WHERE user_id = ?",
    "count": 5,
    "backtrace": ["app/controllers/posts_controller.rb:12"],
    "recorded_at": "2026-06-15T18:00:00.000Z"
  }
]
```

[↑ Back to top](#table-of-contents)

---

## Manual Testing in the Dummy App

The gem ships with a minimal Rails app in `spec/dummy/` for manual verification.

**Start a console:**

```sh
cd spec/dummy
RAILS_ENV=development bin/rails console
```

**Trigger N+1 detection:**

```ruby
QueryOwl.config.enabled = true
QueryOwl::QueryTracker.start!
Widget.all.each { |w| Widget.find(w.id) }
queries = QueryOwl::QueryTracker.stop!
events  = QueryOwl::Detector.detect_n_plus_one(queries)
QueryOwl::Logger.log_events(events)
# => [QueryOwl] {"type":"n_plus_one","sql":"SELECT ...","count":3,...}
```

**Trigger slow query detection:**

```ruby
QueryOwl.config.slow_query_threshold_ms = 0  # flag everything
QueryOwl::QueryTracker.start!
Widget.all.to_a
queries = QueryOwl::QueryTracker.stop!
events  = QueryOwl::Detector.detect_slow_queries(queries)
QueryOwl::Logger.log_events(events)
# => [QueryOwl] {"type":"slow_query","sql":"SELECT ...","duration_ms":...}
```

**Trigger unused eager load detection:**

```ruby
QueryOwl.config.enabled = true
QueryOwl::EagerLoadTracker.start!
Widget.includes(:tags).map(&:name)   # loads tags but never touches them
eager_data = QueryOwl::EagerLoadTracker.stop!
events = QueryOwl::Detector.detect_unused_eager_loads(eager_data)
QueryOwl::Logger.log_events(events)
# => [QueryOwl] {"type":"unused_eager_load","model":"Widget","association":"tags"}
```

**Full pipeline** (as it runs on every real HTTP request):

```ruby
QueryOwl.config.slow_query_threshold_ms = 0
QueryOwl::QueryTracker.start!
QueryOwl::EagerLoadTracker.start!
Widget.all.each { |w| Widget.find(w.id) }
queries    = QueryOwl::QueryTracker.stop!
eager_data = QueryOwl::EagerLoadTracker.stop!
events     = QueryOwl::Detector.detect_n_plus_one(queries) +
             QueryOwl::Detector.detect_slow_queries(queries) +
             QueryOwl::Detector.detect_unused_eager_loads(eager_data)
QueryOwl::Logger.log_events(events)
```

**Seed the dummy database first** (if needed):

```sh
cd spec/dummy
RAILS_ENV=development bin/rails db:migrate
RAILS_ENV=development bin/rails runner "3.times { |i| Widget.create!(name: \"Widget #{i}\") }"
```

[↑ Back to top](#table-of-contents)

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for planned releases, including unused eager load detection (0.2.0) and a `/rails/slow_queries` dashboard endpoint (0.3.0).

[↑ Back to top](#table-of-contents)

---

## Contributing

1. Fork the repo and create a `feat/<name>` branch
2. Write specs for your change
3. Run `bundle exec rake` (lint + audit + tests) before opening a PR

[↑ Back to top](#table-of-contents)

---

## License

MIT — see [MIT-LICENSE](MIT-LICENSE).

[↑ Back to top](#table-of-contents)