# Approval Exit Policy

## 1. Status

Contract only.

This document does not implement code, change runtime behavior, change gateway behavior, add scheduler behavior, or create new actions.

## 2. Purpose

When an approval appears, NeoDaemon must treat it as a safety signal.

The objective is to:

- understand why the approval occurred;
- classify it;
- decide whether approving is safe;
- avoid the same approval recurring unnecessarily.

## 3. Approval Types

Approval events are classified as one of:

```text
APPROVAL_CORRECT
APPROVAL_INCORRECT
APPROVAL_STRUCTURAL
```

## 4. APPROVAL_CORRECT

### Characteristics

An approval is `APPROVAL_CORRECT` when it has all or most of these properties:

- single command;
- exact routes or paths;
- low risk;
- read-only or controlled action;
- safe to approve once.

### Result

```text
APPROVED_ONCE
```

## 5. APPROVAL_INCORRECT

### Characteristics

An approval is `APPROVAL_INCORRECT` when it includes one or more of these properties:

- free shell;
- chained shell operators such as `&&`;
- command separators such as `;`;
- global `find`;
- global `grep`;
- variable paths;
- uncontrolled writing.

### Result

```text
REJECTED
```

## 6. APPROVAL_STRUCTURAL

### Characteristics

An approval is `APPROVAL_STRUCTURAL` when it has one or more of these properties:

- repeated approval;
- recurring blocker;
- necessary to advance;
- likely future integration need.

### Result

```text
APPROVAL_EXIT_REQUIRED
```

## 7. APPROVAL_EXIT_REQUIRED

When the result is `APPROVAL_EXIT_REQUIRED`, NeoDaemon must respond with:

- reason the approval appeared;
- real risk;
- approval classification;
- expected frequency;
- how to avoid it recurring;
- proposed controlled action;
- whether Controlled Discovery applies.

The response must convert the approval from a repeated manual interruption into an explicit design decision.

## 8. Permanent Rule

Never normalize repeated approvals.

If an approval appears several times, NeoDaemon must either:

- create a controlled action; or
- extend Controlled System Discovery.

Approvals are not an operating model. They are a signal that the operating model needs a safer route.

## 9. Out Of Scope

This policy does not authorize or define:

- auto approval;
- approval bypasses;
- free shell;
- unrestricted runtime access.
