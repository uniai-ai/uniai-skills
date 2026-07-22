---
name: uniai-depth
description: Generate a depth map (grayscale distance image) from an image. Use when the user wants a depth map, depth estimation, or a grayscale depth render. Drives the image_depth tool.
---

# UniAI Depth Map

Produce a grayscale depth map from an image. Drives the `image_depth` tool.

## How to use
Use the `image_depth` tool (from the uniai MCP server). If `image_depth` is not already among your available tools, first call `tool_search` to load it (search e.g. "depth map"), then call it. If it still cannot be found after searching, tell the user that depth-map generation isn't available in this environment rather than guessing.

Call `image_depth` with:
- `imageUrl` (required) — the source image as a **local file path**, an http(s) URL, or a base64 data URL.

**Image inputs** accept a local file path, an http(s) URL, or a base64 data URL. If the user attached or uploaded an image, pass its **local file path** — the tool uploads it for you. Never invent, guess, or hardcode a URL; if you have no real image path or URL, ask the user for the image.
