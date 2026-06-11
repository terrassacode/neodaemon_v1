# Operational Control Plane Fixtures v1

## Status

Data-only validation fixtures. No aggregator, runtime, UI, scheduler, alert, Telegram, Gmail, gateway, model, or operational logic changes.

## Purpose

These fixtures define deterministic acceptance cases for the future Operational Control Plane aggregator.

They exist before the aggregator so defective or misleading source signals are not consolidated prematurely.

## Fixture Contract

Each fixture includes:

- `id`
- `description`
- `inputs`
- `expected.status`
- `expected.can_work.local`
- `expected.can_work.start_feature`
- `expected.can_work.heavy_model`
- `expected.risk_level`
- `expected.blockers_include`
- `expected.warnings_include`
- `expected.notes`

## Fixtures

```json
{
  "schema_version": "operational_control_plane.fixtures.v1",
  "contract": "operational_control_plane.v1",
  "fixtures": [
    {
      "id": "all_ok_local_and_feature_ready",
      "description": "Local work and feature start are ready while heavy model work remains cautious because Codex state is unknown.",
      "inputs": {
        "healthcheck": {"status": "OK", "local_can_work_now": true},
        "preflight": {"status": "READY", "can_start_feature": true},
        "codex": {"status": "UNKNOWN"},
        "openclaw_status": {"status": "OK", "checks": {"context_percent": 38, "gateway_reachable": true, "tasks_queued": 0, "tasks_running": 1}},
        "usage_dashboard": {"status": "OK", "confidence": "LOW", "summary": {"last_24h_units": 834268, "previous_24h_units": 14373, "delta_percent": 5704.4, "comparison_stability": "LOW"}}
      },
      "expected": {
        "status": "WARNING",
        "can_work": {"local": true, "start_feature": true, "heavy_model": false},
        "risk_level": "MEDIUM",
        "blockers_include": [],
        "warnings_include": ["HEAVY_MODEL_UNKNOWN"],
        "notes": "Codex UNKNOWN must not block local or feature-start work."
      }
    },
    {
      "id": "heavy_model_blocked",
      "description": "Heavy model work is blocked by an explicit plan limit state.",
      "inputs": {
        "healthcheck": {"status": "OK", "local_can_work_now": true},
        "preflight": {"status": "READY", "can_start_feature": true},
        "codex": {"status": "PLAN_LIMIT_REACHED"},
        "openclaw_status": {"status": "OK", "checks": {"context_percent": 38, "gateway_reachable": true}},
        "usage_dashboard": {"status": "OK", "confidence": "LOW"}
      },
      "expected": {
        "status": "WARNING",
        "can_work": {"local": true, "start_feature": true, "heavy_model": false},
        "risk_level": "HIGH",
        "blockers_include": ["HEAVY_MODEL_PLAN_LIMIT"],
        "warnings_include": [],
        "notes": "Plan limit blocks heavy model work only; local work remains separated."
      }
    },
    {
      "id": "preflight_blocked",
      "description": "Project feature start is blocked by preflight.",
      "inputs": {
        "healthcheck": {"status": "OK", "local_can_work_now": true},
        "preflight": {"status": "BLOCKED", "can_start_feature": false, "blockers": [{"code": "WORKTREE_DIRTY"}]},
        "codex": {"status": "UNKNOWN"},
        "openclaw_status": {"status": "OK"},
        "usage_dashboard": {"status": "OK", "confidence": "LOW"}
      },
      "expected": {
        "status": "BLOCKED",
        "can_work": {"local": true, "start_feature": false, "heavy_model": false},
        "risk_level": "HIGH",
        "blockers_include": ["PREFLIGHT_BLOCKED"],
        "warnings_include": [],
        "notes": "Preflight BLOCKED must prevent feature start."
      }
    },
    {
      "id": "context_warning",
      "description": "OpenClaw status reports high context pressure.",
      "inputs": {
        "healthcheck": {"status": "OK", "local_can_work_now": true},
        "preflight": {"status": "READY", "can_start_feature": true},
        "codex": {"status": "UNKNOWN"},
        "openclaw_status": {"status": "WARNING", "checks": {"context_percent": 70}, "warnings": [{"code": "WARNING_CONTEXT_HIGH"}]},
        "usage_dashboard": {"status": "OK", "confidence": "LOW"}
      },
      "expected": {
        "status": "WARNING",
        "can_work": {"local": true, "start_feature": true, "heavy_model": false},
        "risk_level": "MEDIUM",
        "blockers_include": [],
        "warnings_include": ["WARNING_CONTEXT_HIGH"],
        "notes": "Context pressure warns but does not block by itself in V1."
      }
    },
    {
      "id": "usage_low_base",
      "description": "Usage comparison has a very low previous 24h base and a large percentage delta.",
      "inputs": {
        "healthcheck": {"status": "OK", "local_can_work_now": true},
        "preflight": {"status": "READY", "can_start_feature": true},
        "codex": {"status": "UNKNOWN"},
        "openclaw_status": {"status": "OK"},
        "usage_dashboard": {"status": "WARNING", "confidence": "LOW", "summary": {"last_24h_units": 834268, "previous_24h_units": 14373, "delta_percent": 5704.4, "comparison_stability": "LOW"}}
      },
      "expected": {
        "status": "WARNING",
        "can_work": {"local": true, "start_feature": true, "heavy_model": false},
        "risk_level": "MEDIUM",
        "blockers_include": [],
        "warnings_include": ["USAGE_COMPARISON_LOW_BASE"],
        "notes": "LOW-confidence usage comparison must not block local or feature-start work."
      }
    },
    {
      "id": "invalid_or_missing_signal",
      "description": "One or more required source signals are missing or invalid.",
      "inputs": {
        "healthcheck": {"status": "OK", "local_can_work_now": true},
        "preflight": null,
        "codex": {"status": "UNKNOWN"},
        "openclaw_status": {"status": "OK"},
        "usage_dashboard": {"status": "OK", "confidence": "LOW"}
      },
      "expected": {
        "status": "NO_VERIFICADO",
        "can_work": {"local": true, "start_feature": false, "heavy_model": false},
        "risk_level": "UNKNOWN",
        "blockers_include": [],
        "warnings_include": ["MISSING_PREFLIGHT"],
        "notes": "Missing required signal must remain explicit and not be silently treated as OK."
      }
    }
  ]
}
```

## Notes

- These fixtures are intentionally data-only.
- They do not implement aggregation rules.
- The future aggregator must pass these cases before being considered accepted.
