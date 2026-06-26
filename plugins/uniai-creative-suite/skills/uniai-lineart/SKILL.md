---
name: uniai-lineart
description: Extract clean line-art / a sketch outline from an image. Use when the user wants line art, an outline drawing, a sketch, or coloring-book style from an existing image. Drives the image_lineart tool.
---

# UniAI Line-Art Extraction

Turn an image into a clean line drawing. Drives the `image_lineart` tool.

## How to use
Use the `image_lineart` tool (from the uniai MCP server). If `image_lineart` is not already among your available tools, first call `tool_search` to load it (search e.g. "line art"), then call it. If it still cannot be found after searching, tell the user that line art isn't available in this environment rather than guessing.

Call `image_lineart` with:
- `imageUrl` (required) — the source image as a **local file path**, an http(s) URL, or a base64 data URL.
- `coarse` — `true` for thicker lines, default `false` (fine lines).

**Image inputs** accept a local file path, an http(s) URL, or a base64 data URL. If the user attached or uploaded an image, pass its **local file path** — the tool uploads it for you. Never invent, guess, or hardcode a URL; if you have no real image path or URL, ask the user for the image.
