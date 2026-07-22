---
name: uniai-restore
description: Restore an old/damaged photo (denoise, enhance, face-enhance) and optionally colorize a black-and-white photo. Use when the user wants to repair, restore, enhance, or colorize an old photo. Drives the image_restore tool.
---

# UniAI Photo Restore

Repair and enhance an old photo, optionally colorizing B&W. Drives the `image_restore` tool.

## How to use
Use the `image_restore` tool (from the uniai MCP server). If `image_restore` is not already among your available tools, first call `tool_search` to load it (search e.g. "restore / enhance photo"), then call it. If it still cannot be found after searching, tell the user that photo restoration isn't available in this environment rather than guessing.

Call `image_restore` with:
- `imageUrl` (required) — the photo to restore as a **local file path**, an http(s) URL, or a base64 data URL.
- `colorize` — `true` to colorize a black-and-white photo (default false).
- `restoreLevel` — 1-3, default 2 (higher = stronger).
- `faceEnhance` — default true.

**Image inputs** accept a local file path, an http(s) URL, or a base64 data URL. If the user attached or uploaded a photo, pass its **local file path** — the tool uploads it for you. Never invent, guess, or hardcode a URL; if you have no real image path or URL, ask the user for the photo.
