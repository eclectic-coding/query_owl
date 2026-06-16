# ROADMAP

## 0.7.0 — Dashboard Filtering & Sorting

- Turbo frame wrapping the events table so only the table re-renders on filter or sort changes — no full page reload; adds `importmap-rails`, `turbo-rails`, and `stimulus-rails` as engine dependencies following the same pattern as solid_stack_web
- Filter bar — type dropdown, controller input, clear link; Stimulus `table-filter` controller auto-submits the form on change; filter form targets the turbo frame
- Sortable column headers — server-side sort via `?sort=column&direction=asc/desc`; sort links inside the turbo frame trigger partial re-renders; ▲/▼ indicator on active column; default newest-first

---

## 1.0.0 — Stable Public API

- Locked public configuration interface with deprecation warnings for removed options
- Full README: usage guide, configuration reference, mount instructions, upgrade notes, links to ROADMAP and CONTRIBUTING
- `CONTRIBUTING.md`: setup instructions, test suite guide, PR and commit conventions, bug reporting
- Verified compatibility with Rails 8.1.x and 8.2.x

---
