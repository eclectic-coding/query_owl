# ROADMAP

## 0.7.0 — Dashboard Filtering & Sorting

- Filter bar — type dropdown (All / N+1 / Slow Query / Unused Eager Load), controller input, and active-filter clear link; wires to the existing `?type=` / `?controller=` / `?action=` query params already supported by the JSON API
- Sortable column headers — click Type, Info (duration/count), or Recorded At to toggle asc/desc; client-side sort with no extra server round-trip; default remains newest-first

---

## 1.0.0 — Stable Public API

- Locked public configuration interface with deprecation warnings for removed options
- Full README: usage guide, configuration reference, mount instructions, upgrade notes, links to ROADMAP and CONTRIBUTING
- `CONTRIBUTING.md`: setup instructions, test suite guide, PR and commit conventions, bug reporting
- Verified compatibility with Rails 8.1.x and 8.2.x

---
