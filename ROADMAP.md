# ROADMAP

## 0.7.0 — Dashboard Filtering & Sorting

- [x] Filter bar — type dropdown, controller text input, clear link, Turbo frame partial re-render, Stimulus `table-filter` controller with debounce; floating clear ✕ button; substring controller matching (#56)
- [x] Sortable column headers — server-side sort via `?sort=column&direction=asc/desc`; sort links inside the turbo frame trigger partial re-renders; ▲/▼ indicator on active column; default newest-first (#57)

---

## 1.0.0 — Stable Public API

- Locked public configuration interface with deprecation warnings for removed options
- Full README: usage guide, configuration reference, mount instructions, upgrade notes, links to ROADMAP and CONTRIBUTING
- `CONTRIBUTING.md`: setup instructions, test suite guide, PR and commit conventions, bug reporting
- Verified compatibility with Rails 8.1.x and 8.2.x

---
