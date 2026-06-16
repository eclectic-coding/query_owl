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
- [Notifiers](#notifiers)
- [Ignoring Paths and Controllers](#ignoring-paths-and-controllers)
- [Log Output](#log-output)
- [Dashboard](#dashboard)
- [Test Helper](#test-helper)
- [Rake Tasks](#rake-tasks)
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
- **CI-friendly raise mode** — set `raise_on_n_plus_one: true` to raise `QueryOwl::NPlusOneError` instead of logging
- **Structured log output** — JSON-style warnings via `Rails.logger` with SQL, duration, count, and filtered backtrace
- **HTML dashboard** — browser-accessible event table with filtering and sortable columns
- **Pluggable notifiers** — send events to any destination via a simple `#call(event)` interface
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
rails generate query_owl:install
```

The generator creates `config/initializers/query_owl.rb` with all options documented and commented out.

[↑ Back to top](#table-of-contents)

---

## Configuration

All options are set inside a `QueryOwl.configure` block, typically in `config/initializers/query_owl.rb`.

| Option | Type | Default | Description |
|---|---|---|---|
| `enabled` | Boolean | `Rails.env.development?` | Master on/off switch |
| `slow_query_threshold_ms` | Integer | `100` | Flag queries slower than this many milliseconds |
| `n_plus_one_threshold` | Integer | `2` | Flag when the same SQL pattern fires this many times per request |
| `log_level` | Symbol | `:warn` | Log level for warnings — `:debug`, `:info`, or `:warn` |
| `backtrace_lines` | Integer | `5` | Number of backtrace frames captured per query |
| `backtrace_filter` | Callable | strips gem/internal paths | Proc that receives a line and returns `true` to keep it |
| `raise_on_n_plus_one` | Boolean | `false` | Raise `QueryOwl::NPlusOneError` instead of logging |
| `event_store_size` | Integer | `100` | Ring buffer capacity (oldest events dropped when full) |
| `dashboard_enabled` | Boolean | `Rails.env.development?` | Enable the HTML dashboard at `GET /slow_queries` |
| `log_file` | String / nil | `nil` | Append each event as a JSON line to this file path |
| `notifiers` | Array | `[Notifiers::Logger]` | Objects responding to `#call(event)` — see [Notifiers](#notifiers) |
| `ignore_paths` | Array | `[]` | Path prefixes or regexes to skip entirely |
| `ignore_controllers` | Array | `[]` | Controller names to skip after routing |

Example:

```ruby
QueryOwl.configure do |config|
  config.enabled                 = Rails.env.development?
  config.slow_query_threshold_ms = 100
  config.n_plus_one_threshold    = 2
  config.log_level               = :warn
  config.backtrace_lines         = 5
  config.raise_on_n_plus_one     = false
  config.event_store_size        = 100
  config.dashboard_enabled       = Rails.env.development?
  config.log_file                = Rails.root.join("log/query_owl.log").to_s
  config.ignore_paths            = ["/up", "/healthz", %r{^/assets/}]
  config.ignore_controllers      = ["rails/health"]
  config.notifiers               = [QueryOwl::Notifiers::Console.new]
end
```

[↑ Back to top](#table-of-contents)

---

## Notifiers

Notifiers receive each detected event via `#call(event)`. Any object responding to `#call` is valid.

**Built-in notifiers:**

| Notifier | Description |
|---|---|
| `QueryOwl::Notifiers::Logger` | Writes to `Rails.logger` (default) |
| `QueryOwl::Notifiers::Console` | TTY-aware colorized output — yellow for N+1s, red for slow queries; falls back to plain output in CI |
| `QueryOwl::Notifiers::Stdout` | Writes to `$stdout`; useful for background jobs and Rake tasks |

**Custom notifier:**

```ruby
my_notifier = ->(event) { MyService.track(event) }

QueryOwl.configure do |config|
  config.notifiers = [QueryOwl::Notifiers::Logger.new, my_notifier]
end
```

A failing notifier is rescued and logged via `Rails.logger.error` — it cannot crash the request or prevent other notifiers from running.

[↑ Back to top](#table-of-contents)

---

## Ignoring Paths and Controllers

Skip high-frequency or low-value requests to reduce noise:

```ruby
QueryOwl.configure do |config|
  # String entries match as path prefix; Regexp entries use #match?
  config.ignore_paths = ["/up", "/healthz", %r{^/assets/}]

  # Match against the Rails controller name (e.g. "rails/health")
  config.ignore_controllers = ["rails/health", "admin/metrics"]
end
```

Ignored paths are detected before tracking starts — no SQL or eager load data is collected. Ignored controllers are detected after routing — trackers still stop cleanly, but no events are dispatched.

[↑ Back to top](#table-of-contents)

---

## Log Output

When an issue is detected, QueryOwl writes a structured line to `Rails.logger`:

```
[QueryOwl] {"type":"n_plus_one","sql":"SELECT * FROM posts WHERE user_id = ?","count":10,"controller":"posts","action":"index","path":"/posts","backtrace":["app/controllers/posts_controller.rb:12"]}
[QueryOwl] {"type":"slow_query","sql":"SELECT * FROM reports WHERE ...","duration_ms":340,"controller":"reports","action":"show","path":"/reports/1"}
[QueryOwl] {"type":"unused_eager_load","model":"Widget","association":"tags","controller":"widgets","action":"index","path":"/widgets"}
[QueryOwl] Request complete — 10 N+1s, 1 slow query, 1 unused eager load
```

When `log_file` is set, each event is also appended as a JSON line to that file — useful for persistence across server restarts.

[↑ Back to top](#table-of-contents)

---

## Dashboard

Mount the engine in your routes to enable the dashboard:

```ruby
# config/routes.rb
mount QueryOwl::Engine => "/rails"
```

**HTML dashboard** at `GET /rails/slow_queries` (requires `config.dashboard_enabled = true`, default in development):

- Filter by event type and controller name (partial match supported)
- Sortable columns: Type, Info, Recorded At (click to toggle asc/desc)
- Turbo-powered — filter and sort changes replace only the table, not the full page

**JSON endpoint** at `GET /rails/slow_queries.json` (always available regardless of `dashboard_enabled`):

```
GET /rails/slow_queries.json
GET /rails/slow_queries?type=n_plus_one
GET /rails/slow_queries?type=slow_query
GET /rails/slow_queries?type=unused_eager_load
GET /rails/slow_queries?controller=widgets
GET /rails/slow_queries?action=index
GET /rails/slow_queries?sort=recorded_at&direction=asc
```

**Example JSON response:**

```json
[
  {
    "type": "n_plus_one",
    "sql": "SELECT * FROM posts WHERE user_id = ?",
    "count": 5,
    "controller": "posts",
    "action": "index",
    "path": "/posts",
    "backtrace": ["app/controllers/posts_controller.rb:12"],
    "recorded_at": "2026-06-15T18:00:00.000Z"
  }
]
```

**Clear the event store** without restarting the server:

```sh
rails query_owl:clear
```

[↑ Back to top](#table-of-contents)

---

## Test Helper

QueryOwl ships an opt-in test helper with RSpec matchers and Minitest assertions.

**Setup (RSpec):**

```ruby
# spec/rails_helper.rb
require "query_owl/test_helper"
RSpec.configure { |c| c.include QueryOwl::TestHelper }
```

**Setup (Minitest):**

```ruby
# test/test_helper.rb
require "query_owl/test_helper"
class ActiveSupport::TestCase
  include QueryOwl::TestHelper
end
```

**RSpec matchers:**

```ruby
expect { Post.all.each(&:author) }.not_to trigger_n_plus_one
expect { slow_operation }.not_to trigger_slow_query
expect { Widget.includes(:tags).map(&:name) }.not_to trigger_unused_eager_load
```

**Minitest assertions:**

```ruby
assert_no_n_plus_one { Post.all.each(&:author) }
assert_no_slow_query  { slow_operation }
```

Each helper runs the block with trackers active, isolated from `config.enabled` and `config.raise_on_n_plus_one`.

[↑ Back to top](#table-of-contents)

---

## Rake Tasks

```sh
rails query_owl:clear   # drain the in-memory event store
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
Widget.includes(:tags).map(&:name)
eager_data = QueryOwl::EagerLoadTracker.stop!
events = QueryOwl::Detector.detect_unused_eager_loads(eager_data)
QueryOwl::Logger.log_events(events)
# => [QueryOwl] {"type":"unused_eager_load","model":"Widget","association":"tags"}
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

See [ROADMAP.md](ROADMAP.md) for planned features.

[↑ Back to top](#table-of-contents)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions, conventions, and how to report bugs.

[↑ Back to top](#table-of-contents)

---

## License

MIT — see [MIT-LICENSE](MIT-LICENSE).

[↑ Back to top](#table-of-contents)