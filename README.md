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

## Contributing

1. Fork the repo and create a `feat/<name>` branch
2. Write specs for your change
3. Run `bundle exec rake` (lint + audit + tests) before opening a PR

## License

MIT — see [MIT-LICENSE](MIT-LICENSE).