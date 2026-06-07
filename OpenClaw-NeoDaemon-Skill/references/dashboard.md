# Dashboard

## Goal

Use dashboard-v2 as the visual entrypoint for observability.

Dashboard surfaces must stay read-only:

- no merge;
- no push;
- no delete;
- no execution buttons.

## Current Data

Relevant data sources include:

- `dashboard-v2/data/token_dashboard.json`
- `dashboard-v2/data/resource_usage_metrics.json`
- `dashboard-v2/data/status_summary.json`
- `dashboard-v2/data/github_reviewer_status.json`
- `docs/status/project-dashboard-state-v1.json`

## Sources To Read

- `docs/status/dashboard-base-minimal-v1.md`
- `docs/status/project-dashboard-state-v1.json`
