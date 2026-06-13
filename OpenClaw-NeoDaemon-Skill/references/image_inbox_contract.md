# Image Inbox Contract

## Status

Contract only.

This document does not implement UI, upload behavior, runtime behavior, gateway behavior, scheduler behavior, OCR, embeddings, or automatic image analysis.

## Purpose

Define the minimum safe contract for an image inbox so Albert can provide one image for NeoDaemon to inspect later.

The inbox is a simple handoff mechanism, not a media manager.

## Allowed Formats

Only these image formats are allowed:

```text
jpg
jpeg
png
webp
```

Any other format must be rejected.

## Size Limit

Maximum image size:

```text
5 MB
```

Files larger than this limit must be rejected before persistence.

## Request Limit

Each request may contain only:

```text
1 image
```

Multiple images require separate requests.

## Filename Rules

The filename must be sanitized before storage.

The implementation must:

- remove or replace unsafe characters;
- block path traversal;
- prevent absolute paths;
- prevent parent-directory references;
- avoid trusting user-provided paths;
- preserve only a safe display filename.

## No Overwrite

The image inbox must not overwrite existing files.

If a sanitized filename already exists, the implementation must create a distinct safe stored filename or reject the request.

## Metadata

Each accepted image must have minimum metadata:

```text
id
filename
uploaded_at
uploaded_by
status
```

The metadata must be enough for NeoDaemon to identify the image and report whether it has been reviewed.

## Status Values

Allowed statuses:

```text
pending
viewed
processed
```

No other status is valid unless this contract is updated.

## Permissions

NeoDaemon may:

- read the image;
- read metadata;
- update status.

NeoDaemon must not:

- delete the image;
- rename the image;
- delete metadata.

## Out Of Scope

This inbox does not include:

- OCR;
- embeddings;
- gallery behavior;
- multiple images per request;
- PDF;
- zip;
- video;
- semantic search;
- automatic analysis;
- tagging;
- folders;
- thumbnails;
- media management.

## Permanent Rule

```text
Accept one safe image.
Expose it to NeoDaemon.
Do nothing else automatically.
```
