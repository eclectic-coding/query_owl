# Contributing to QueryOwl

Thank you for your interest in contributing! This document covers how to set up the project locally, run the test suite, and submit changes.

## Setup

1. Fork and clone the repo
2. Install dependencies:

   ```sh
   bundle install
   ```

3. Verify everything works:

   ```sh
   bundle exec rake
   ```

   The default task runs lint → security audit → specs.

## Running tests

```sh
# Full CI suite (lint + audit + specs)
bundle exec rake

# Specs only
bundle exec rspec

# Single spec file
bundle exec rspec spec/path/to/file_spec.rb

# Lint only
bin/rubocop

# Security audit
bundle exec bundle-audit check
```

Coverage is reported to `coverage/` (gitignored). The suite enforces 100% line coverage — all new code must be accompanied by specs.

## Making changes

1. Create a branch: `git checkout -b feat/<short-description>`
2. Write specs first (or alongside your change)
3. Run `bundle exec rake` before every commit — CI runs the same suite on Ruby 3.3, 3.4, and 4.0
4. Keep commits focused; use conventional prefixes: `feat:`, `fix:`, `docs:`, `refactor:`

## Submitting a PR

- Open a pull request against `main`
- Describe what changed and why
- All CI checks must pass before merge

## Reporting bugs

Please open an issue at https://github.com/eclectic-coding/query_owl/issues and include:

- Ruby and Rails versions
- A minimal reproduction (controller action, model, or inline script)
- The log output or error message you observed