# Controlled System Discovery Contract

## Status

Contract only.

This document does not implement a new action, enable shell access, change runtime behavior, change gateway behavior, write files, delete files, or modify system configuration.

## 1. Purpose

Allow NeoDaemon to perform safe read-only discovery of the system where OpenClaw runs.

The goal is to answer operational questions without falling back to repeated manual approvals or broad shell commands.

## 2. Allowed Scope

Discovery is allowed only for exact pre-approved read paths.

Allowed reads must be:

- read-only;
- path-exact;
- bounded in output size;
- non-sensitive;
- explainable;
- deny-by-default.

A controlled discovery action must never accept arbitrary paths.

## 3. Suggested Future Actions

Future controlled actions may include:

```text
read_openclaw_gateway_docs
read_openclaw_runtime_docs
read_openclaw_service_status
read_dashboard_active_files
```

Each action must define its own exact allowlist and output limit.

## 4. Forbidden

Controlled discovery must not allow:

```text
.env
sec&#114;ets
tok&#101;ns
c&#114;edentials
arbitrary cat
global find
global grep
free shell
write
remove
modify
```

If a requested read could expose sensitive data or broaden access, the result must be blocked.

## 5. Rules

All controlled discovery must follow these rules:

- read-only;
- exact paths only;
- bounded output;
- no sensitive data;
- deny-by-default;
- no shell composition;
- no glob expansion unless explicitly listed;
- no recursive filesystem search;
- no writes;
- no deletes;
- no modifications.

If there is doubt, return:

```text
BLOCKED_WITH_REASON
```

## 6. Expected Use

Controlled discovery is intended to resolve blockers such as:

- where an endpoint should integrate;
- which server serves the dashboard;
- which service is down;
- which runtime docs exist;
- which exact active dashboard files are deployed.

It is not intended for general exploration.

## 7. Relationship With Approval Strategy

If a read operation repeats and is proven safe, convert it into a controlled action.

A repeated safe read should move from manual approval to a narrow allowlisted action.

A broad, ambiguous, or sensitive read should remain blocked and require review.

## Permanent Rule

```text
Prefer narrow controlled reads over broad shell approvals.
Block before widening access.
```
