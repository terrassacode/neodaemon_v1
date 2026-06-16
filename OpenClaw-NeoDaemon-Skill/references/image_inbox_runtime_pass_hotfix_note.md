# Image Inbox Runtime Pass Hotfix Note

Status: PASS

Manual hotfix:
- Commit: dc6a053
- Change: added auth: "gateway" to image-inbox health route.
- Reason: OpenClaw requires explicit auth on registerHttpRoute.
- Previous diagnostic: http route registration missing or invalid auth.
- Previous runtime state: httpRoutes=0, diagnostics not empty.

Validated result:
- openclaw plugins inspect image-inbox --runtime --json
- status: loaded
- httpRoutes: 1
- diagnostics: []

Gateway validation:
- openclaw gateway call health --json
- plugins.loaded includes image-inbox.

Expected HTTP behavior:
- curl without token to /plugin/image-inbox/health returns 401 Unauthorized.
- This is expected because auth: "gateway" keeps gateway auth enabled.

Conclusion:
IMAGE_INBOX_RUNTIME_PASS with gateway auth.
