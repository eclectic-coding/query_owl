# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`query_owl` is a Rails engine gem (API-only) still in early development. The engine is namespaced under `QueryOwl` with `isolate_namespace` and `config.generators.api_only = true`. The gem targets Rails >= 8.1.3 and Ruby 3.3+.

## Commands

```bash
# Run the full CI suite (lint → security audit → specs)
bundle exec rake

# Run specs only
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/path/to/file_spec.rb

# Lint
bin/rubocop

# Security audit
bundle exec bundle-audit update && bundle exec bundle-audit check

# Release (bumps version, updates CHANGELOG, tags, and pushes)
bin/release <version>   # e.g. bin/release 0.2.0
```

The default `rake` task runs: `lint → bundle:audit:update → bundle:audit:check → spec`.

## Architecture

```
lib/query_owl.rb          # Requires version + engine; main module entry point
lib/query_owl/engine.rb   # Rails::Engine with isolate_namespace and API-only generators
lib/query_owl/version.rb  # VERSION constant

app/                      # Standard engine app/ layout (controllers, models, jobs, mailers)
  controllers/query_owl/application_controller.rb  # Inherits ActionController::API
  models/query_owl/application_record.rb           # Abstract base record

config/routes.rb          # Engine routes (currently empty)
spec/dummy/               # Minimal Rails app used as the test harness
spec/rails_helper.rb      # Loads dummy app; uses transactional fixtures
spec/spec_helper.rb       # Loads SimpleCov (HTML + JSON output to coverage/)
```

All application code lives under the `QueryOwl` module. The dummy app in `spec/dummy/` is the Rails host used only for running specs — it is not shipped with the gem.

## Style conventions

- RuboCop config inherits `rubocop-rails-omakase`; double-quoted strings enforced; `spec/**` excluded from linting.
- CI tests against Ruby 3.3, 3.4, and 4.0. Target Ruby version for RuboCop is 3.3.
- Coverage is reported to Codecov via `coverage/coverage.json` (JSON formatter); the `coverage/` directory is gitignored.
- Publishing is triggered by pushing a `v*` tag; `bin/release` automates the full release workflow.