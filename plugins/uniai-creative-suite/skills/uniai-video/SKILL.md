---
name: uniai-video
description: Generate a short video clip with UniAI video models — from a text prompt, or guided by images/video (animate a photo, interpolate first→last frame, restyle a clip, extend a video). Use when the user asks to create/generate a video, animation, motion graphic, or moving clip from text, to animate an uploaded image (e.g. a product photo), or to edit/extend an existing video (e.g. "make a video of ...", "animate this photo", "turn this image into a video", "extend this clip").
---

# UniAI Video Generation

Turn text — or an image/video — into a short video clip using UniAI's video models, driven by the `generate_video` tool (uniai MCP server). The available models come from the platform's live catalog (the same one the web app shows); which modes each model supports varies by model, so never assume a fixed model or that every mode works on every model.

## Workflow — clarify, then confirm, then generate

Always follow this order. Do NOT call `generate_video` the instant the user asks for a video.

1. **Clarify the request and key parameters first.** Make sure you understand: the scene/motion, which mode applies (text vs animate-an-image vs reference vs edit/extend a clip — see the Decision tree), aspect ratio, duration, resolution, and which media (first frame / references / source video) the user is providing.
2. **Call `generate_video`, passing ONLY the parameters the user explicitly stated** (besides `type`, which you pick from the media — see below). The tool pops **one confirmation popup per parameter the user did NOT specify**: model (listing only models that support your chosen `type`, with friendly names), then aspect ratio, duration (the **model's own allowed lengths** — some only offer fixed steps), resolution, and audio on/off for models that support sound. Each is pre-filled with a recommended default. Parameters the user *did* specify are used directly — no popup. So pass `duration: 8` only if the user asked for 8s; leave it unset otherwise so the user is asked. Popups appear only for unspecified parameters with a real choice.
3. **Generation runs only after the user confirms every popup.** If the user cancels any popup, the tool returns a "cancelled, nothing generated, no credits charged" message — ask how they want to adjust, then call again. (In unattended/automation runs there are no popups: the tool uses the recommended model + parameters automatically.)

Pick the `type` from the media the user gave you — `type` is part of the request you clarified up front, not something the popups change. Don't pre-fill the other parameters the user didn't ask for — leaving them unset is what triggers their confirmation popup. The popup set is **dynamic per request**.

## Approach (one path)

One tool, several modes selected by the `type` argument. There is no CLI and no API key — auth and billing are handled by the platform. If `generate_video` isn't among your tools, call `tool_search` ("generate video") first; if still missing, tell the user it isn't available here rather than guessing.

## When to use
- Generate a video from a text description.
- **Animate an image** the user has (e.g. a product photo → a rotating/showcase clip).
- Interpolate between a first and last frame, restyle/edit an existing clip, or extend a video.

## When not to use
- Still images → use the `generate_image` tool.
- Lip-sync or motion-transfer (driving a character with audio / copying motion from a reference video) — **not available** in this environment yet; don't promise it.

## Decision tree — pick the `type`

| `type` | Use when | Required input (besides `prompt`) |
|--------|----------|-----------------------------------|
| `text2video` (default) | Pure text-to-video, no source media | — |
| `image2video` | Animate one image (the user's photo / a generated image) | `firstFrame` |
| `start_end_frame` | Interpolate a motion from a first frame to a last frame | `firstFrame` + `lastFrame` |
| `reference_to_video` | Guide style / subject / character with reference images | `referenceImages` (≥1) |
| `video_to_video` | Edit or restyle an existing clip | `sourceVideo` (+ optional `v2vEndpoint`) |
| `video_continuation` | Extend / continue a clip | `continuationVideo` |

Assume `text2video` unless the user provides (or asks to use) an image or video.

## Calling generate_video

Common arguments:
- `prompt` (required) — scene / motion description (see Prompt tips).
- `type` — one of the modes above; default `text2video`.
- `model` — optional; **leave unset** so the platform recommends one and the confirmation dialog offers the models that support your chosen `type`. Only set it if the user named a specific model. Don't hardcode a model id otherwise.
- `aspectRatio` — `16:9` (default), `9:16`, `1:1`, `4:3`, `3:4`, `3:2`, `2:3`, `21:9`, or `adaptive` (match the input media).
- `duration` — seconds (default 5). Allowed lengths are **per-model** — many models only offer fixed steps (e.g. 4/5/8/10/12s); the confirmation popup lists the selected model's allowed durations. Longer costs more.
- `resolution` — `720p` or `1080p` (optional). Higher costs more.
- `negativePrompt`, `seed` — optional (negativePrompt only applies on some models).

Media inputs — each accepts a **local file path**, an http(s) URL, or a base64 data URL. **For files the user uploaded, pass their local paths; the tool uploads them for you. Never invent a URL.**
- `firstFrame`, `lastFrame` — images.
- `referenceImages` — array of images (up to 9).
- `sourceVideo`, `continuationVideo` — videos (MP4/WebM/MOV).
- `v2vEndpoint` — `edit` (default, modify the source, keep its length) or `reference` (new scene using the source as cinematic reference).

After the tool returns a URL, present or save it (see Output). Generation usually takes ~1–5 minutes; tell the user it is processing rather than assuming it failed.

## Multi-clip / consistency (read this for a series)

When producing several clips meant to feel like one product/subject:
- **Re-attach the SAME source media to EVERY call.** Each call is independent — if you drop `firstFrame`/`referenceImages` on a later call, that clip becomes unrelated.
- **Always use the user's ORIGINAL upload** as the input — never a previously generated clip's frame as the reference (that compounds drift).
- **Carry the exact local path** across calls; if you lose it, stop and ask the user rather than generating without it.
- Generate one clip per call; for a multi-scene sequence, issue several calls (or use `video_continuation` to extend).

## Prompt tips

Describe **one continuous shot**, concretely: subject + action → scene/setting → camera (shot type + movement) → lighting/mood/style. Keep unrelated scenes out of one prompt.

Example (text2video):
> A lone red fox leaps over a fallen log in a misty autumn forest at dawn, slow dolly-in, shallow depth of field, warm golden-hour light, cinematic, photorealistic.

Example (image2video — animate a product photo):
→ `generate_video({ type: "image2video", prompt: "the sneaker slowly rotates 360° on a turntable, soft studio light", firstFrame: "~/Desktop/sneaker.png", aspectRatio: "1:1" })`

## Output / save policy

`generate_video` returns a video **URL** (and a cover URL) — not a local file.
- Preview/brainstorm: present the URL inline.
- Project-bound: download into the workspace (e.g. `curl -o assets/clip.mp4 "<url>"`) and wire it in. Never leave a project-referenced video as only a remote URL.
- Don't overwrite an existing asset unless asked — use a versioned name (`clip-v2.mp4`).
- Always report the final saved path(s), the mode (`type`), and key params used.

## Constraints
- `duration` 2–15s; `type` must be one of the six modes above (lip-sync / motion-transfer are not available).
- Mode-specific media is required (see the Decision tree) — the tool will error clearly if a required input is missing.
- Uploaded videos must be MP4/WebM/MOV (≤100MB); images ≤50MB.
- Capabilities vary by model — supported modes, durations, and resolutions differ. You don't need to memorize them: the confirmation dialog only lists models that support your chosen `type` and shows each one's valid parameters, and the platform rejects out-of-range values.
- Cost scales with `duration`, `resolution`, and number of reference inputs — keep them minimal unless the user asks for more.
