# Operational Control Plane Contract v1

## Status

Contract only. No runtime, gateway, model, scheduler, alert, Telegram, Gmail, UI, or dashboard changes.

## Purpose

Operational Control Plane V1 defines a single read-only source of truth for NeoDaemon/OpenClaw operational state.

It must answer:

- can NeoDaemon work locally now?
- can NeoDaemon start a Project Executor feature now?
- can NeoDaemon safely launch heavy model/Codex work now?
- what is the current operational risk?
- what is the next minimum action?

## Required Separation

V1 must always separate:

```text
can_work.local
can_work.start_feature
can_work.heavy_model
```

A local operation may be allowed while heavy model work is warning or blocked.

## JSON Contract

```json
{
  "schema_version": "operational_control_plane.v1",
  "generated_at": null,
  "status": "OK | WARNING | DEGRADED | BLOCKED | NO_VERIFICADO",
  "risk_level": "LOW | MEDIUM | HIGH | UNKNOWN",
  "can_work": {
    "local": true,
    "start_feature": true,
    "heavy_model": false
  },
  "confidence": {
    "healthcheck": "HIGH",
    "preflight": "HIGH",
    "codex": "MEDIUM",
    "openclaw_status": "MEDIUM",
    "usage_dashboard": "LOW"
  },
  "signals": {
    "healthcheck": {
      "status": "OK | DEGRADED | BLOCKED | NO_VERIFICADO",
      "confidence": "HIGH",
      "summary": {}
    },
    "preflight": {
      "status": "READY | DEGRADED | BLOCKED | NO_VERIFICADO",
      "confidence": "HIGH",
      "summary": {}
    },
    "codex": {
      "status": "AVAILABLE | PLAN_LIMIT_REACHED | RATE_LIMIT_OR_COOLDOWN | SIGNIN_ERROR | UNKNOWN",
      "confidence": "MEDIUM",
      "summary": {}
    },
    "openclaw_status": {
      "status": "OK | WARNING | DEGRADED | NO_VERIFICADO",
      "confidence": "MEDIUM",
      "summary": {}
    },
    "usage_dashboard": {
      "status": "OK | WARNING | DEGRADED | NO_VERIFICADO",
      "confidence": "LOW",
      "summary": {
        "last_24h_units": null,
        "previous_24h_units": null,
        "delta_percent": null,
        "comparison_stability": "OK | LOW | UNKNOWN"
      }
    }
  },
  "derived": {
    "context_percent": null,
    "usage_comparison_stability": "OK | LOW | UNKNOWN",
    "blocking_reason": null
  },
  "blockers": [],
  "warnings": [],
  "recommended_next_action": "string",
  "safe": true,
  "logs_redacted": true
}
```

## Confidence Model

### HIGH

A HIGH-confidence signal is:

- local and direct;
- deterministic;
- functionally validated;
- low risk for misleading interpretation.

HIGH signals may allow or block local/start-feature decisions.

### MEDIUM

A MEDIUM-confidence signal is:

- useful but partial;
- possibly stale;
- possibly dependent on external output format;
- not proof of end-to-end availability.

MEDIUM signals may raise risk. They may block only when they report an explicit blocking state.

### LOW

A LOW-confidence signal is:

- mathematically valid but operationally ambiguous;
- useful for context and trend interpretation;
- not reliable as a blocking source by itself in V1.

LOW signals must remain visible as warnings/context but must not block by themselves.

## Initial Signal Confidence

```json
{
  "healthcheck": "HIGH",
  "preflight": "HIGH",
  "codex": "MEDIUM",
  "openclaw_status": "MEDIUM",
  "usage_dashboard": "LOW"
}
```

## Source Responsibilities

### healthcheck

Primary source for:

```text
can_work.local
```

Expected signal:

```text
neodaemon_healthcheck_v1.py
```

### preflight

Primary source for:

```text
can_work.start_feature
```

Expected signal:

```text
project_executor_preflight_v1.py
```

### codex

Primary source for:

```text
can_work.heavy_model
```

Expected signal:

```text
codex_status_readonly_v1.py
```

Rules:

- `PLAN_LIMIT_REACHED` blocks heavy model work.
- `SIGNIN_ERROR` blocks heavy model work.
- `RATE_LIMIT_OR_COOLDOWN` blocks heavy model work until state clears.
- `UNKNOWN` does not block local work, but raises heavy-model risk.

### openclaw_status

Source for:

- context pressure;
- gateway signal;
- task pressure;
- model/session context.

Expected signal:

```text
openclaw_status_signal_summary_v1.py
```

### usage_dashboard

Source for:

- activity trend;
- last 24h usage;
- previous 24h usage;
- comparison stability.

Rules:

- usage dashboard is LOW confidence in V1.
- it must not block by itself.
- it may add warnings such as low comparison base or unusual activity deltas.

## Required Phase Order

```text
Fase 0 — Contract
Fase 1 — Validation Fixtures
Fase 2 — Aggregator
Fase 3 — Human Summary
Fase 4 — Consumers
```

Reason:

Fixtures must exist before the aggregator so defective or misleading signals are not consolidated prematurely.

## Acceptance Criteria For This Contract

- schema version is explicit;
- confidence model is defined;
- source responsibilities are defined;
- `can_work.local`, `can_work.start_feature`, and `can_work.heavy_model` are separate;
- usage dashboard is LOW confidence;
- consumers are explicitly out of scope;
- no runtime, gateway, model, scheduler, alert, Telegram, Gmail, UI, or dashboard change is introduced.

## Out Of Scope For V1 Contract

- implementation of the aggregator;
- visual dashboard;
- Telegram feedback;
- alerts;
- scheduler;
- runtime integration;
- model fallback;
- automatic corrective actions.
