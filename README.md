# QueryOwl

[![CI](https://github.com/eclectic-coding/query_owl/actions/workflows/main.yml/badge.svg)](https://github.com/eclectic-coding/query_owl/actions/workflows/main.yml)
[![Gem Version](https://img.shields.io/gem/v/query_owl)](https://rubygems.org/gems/query_owl)
[![Downloads](https://img.shields.io/gem/dt/query_owl)](https://rubygems.org/gems/query_owl)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-ruby)](https://www.ruby-lang.org)
[![codecov](https://codecov.io/gh/eclectic-coding/query_owl/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/query_owl)

A leaner alternative to Bullet. QueryOwl detects N+1 queries and slow queries in development, logging structured warnings to your Rails logger — without the noise.

## Features

- **N+1 detection** — flags when the same SQL pattern fires 2+ times in a single request
- **Slow query detection** — flags queries exceeding a configurable threshold (default: 100ms)
- **Structured log output** — JSON-style warnings via `Rails.logger` with SQL, duration, count, and filtered backtrace
- **Zero overhead in production** — auto-enabled in development only

## Installation

Add to your `Gemfile`:

```ruby
gem "query_owl"
```

Then run:

```sh
bundle install
```

## Configuration

Create an initializer:

```ruby
# config/initializers/query_owl.rb
QueryOwl.configure do |config|
  config.enabled                = Rails.env.development?
  config.slow_query_threshold_ms = 100   # flag queries slower than this
  config.n_plus_one_threshold   = 2      # flag after this many repeated patterns
  config.log_level              = :warn  # :warn | :info | :debug
end
```

## Log Output

When a problem is detected, QueryOwl writes a structured line to `Rails.logger`:

```
[QueryOwl] {"type":"n_plus_one","sql":"SELECT * FROM posts WHERE user_id = ?","count":10,"backtrace":["app/controllers/posts_controller.rb:12"]}
[QueryOwl] {"type":"slow_query","sql":"SELECT * FROM reports WHERE ...","duration_ms":340}
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for planned releases, including unused eager load detection (0.2.0) and a `/rails/slow_queries` dashboard endpoint (0.3.0).

## Manual Testing in the Dummy App

The gem ships with a minimal Rails app in `spec/dummy/` for manual verification.

**Start a console:**

```sh
cd spec/dummy
RAILS_ENV=development bin/rails console
```

**Trigger N+1 detection:**

```ruby
# Enable the gem (development is on by default, but make sure)
QueryOwl.config.enabled = true

# Simulate a request — start the tracker, fire repeated queries, stop and log
QueryOwl::QueryTracker.start!
3.times { |i| Widget.find(i + 1) rescue nil }
queries = QueryOwl::QueryTracker.stop!
events  = QueryOwl::Detector.detect_n_plus_one(queries) +
          QueryOwl::Detector.detect_slow_queries(queries)
QueryOwl::Logger.log_events(events)
# => logs: [QueryOwl] {"type":"n_plus_one","sql":"SELECT ...","count":3,...}
```

**Trigger slow query detection:**

```ruby
QueryOwl.config.slow_query_threshold_ms = 0  # flag everything

QueryOwl::QueryTracker.start!
Widget.all.to_a
queries = QueryOwl::QueryTracker.stop!
events  = QueryOwl::Detector.detect_slow_queries(queries)
QueryOwl::Logger.log_events(events)
# => logs: [QueryOwl] {"type":"slow_query","sql":"SELECT ...","duration_ms":...}
```

**Seed the dummy database first** (if needed):

```sh
cd spec/dummy
RAILS_ENV=development bin/rails db:migrate
RAILS_ENV=development bin/rails runner "3.times { |i| Widget.create!(name: \"Widget #{i}\") }"
```

## Contributing

1. Fork the repo and create a `feat/<name>` branch
2. Write specs for your change
3. Run `bundle exec rake` (lint + audit + tests) before opening a PR

## License

MIT — see [MIT-LICENSE](MIT-LICENSE).