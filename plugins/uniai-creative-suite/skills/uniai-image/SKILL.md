---
name: uniai-image
description: Generate images for the current task (website/app assets, product or UI mockups, hero images, logos, illustrations, photorealistic images, infographics, concept art) from a text prompt — optionally guided by reference images (image-to-image: variation, style, or character consistency). Use when the user asks to create, generate, make, or draw an image, or to make a variation of / a new image in the style of an existing or uploaded image (e.g. "make an image of a cat", "a variation of this image", "in the style of this photo").
---

# UniAI Image Generation

Turn a text prompt — optionally guided by reference images — into a still image using UniAI's image models, driven by the `generate_image` tool (uniai MCP server). The available models come from the platform's live catalog (the same one the web app shows), so the exact model list and per-model capabilities can change; never assume a fixed model or fixed limits.

## Workflow — clarify, then confirm, then generate

Always follow this order. Do NOT call `generate_image` the instant the user asks for an image.

1. **Clarify the request and key parameters first.** Make sure you understand: what to depict, the intended use/asset type, style direction, aspect ratio intent, how many variants, and any reference images. If the request is ambiguous on something that materially changes the output, ask a brief question before proceeding (see Prompt augmentation).
2. **Call `generate_image`, passing ONLY the parameters the user explicitly stated.** This is important: the tool pops **one confirmation popup per parameter the user did NOT specify** (model, aspect ratio, quality *or* resolution depending on the model, count), each pre-filled with a recommended default and shown with friendly model names. Parameters the user *did* specify (e.g. they said "16:9" or named a model) are used directly — **no popup for those**. So pass `aspectRatio: "16:9"` only if the user asked for 16:9; leave it unset otherwise so the user is asked. Popups appear only for unspecified parameters that have a real choice.
3. **Generation runs only after the user confirms every popup.** If the user cancels any popup, the tool returns a "cancelled, nothing generated, no credits charged" message — do not retry blindly; ask how they want to adjust, then call again. (In unattended/automation runs there are no popups: the tool uses the recommended model + parameters automatically.)

Do NOT pre-fill parameters the user didn't ask for — leaving them unset is what triggers the confirmation popup for them. The popup set is **dynamic per request**: nail down what the user said, pass exactly that, and the user is asked about the rest.

## Approach (one path)

There is exactly one path: the `generate_image` tool. There is **no CLI, no OpenAI API key, and no local script** — authentication and billing are handled by the platform. To *edit* an existing image (not generate a new one), route to the dedicated edit tools instead — see the Decision tree.

If `generate_image` is not among your available tools, first call `tool_search` (e.g. "generate image" / "uniai image"), then call it. If it still cannot be found, tell the user that image generation isn't available in this environment rather than guessing.

## When to use
- Generate a new image (hero, product shot, cover, concept art, logo, illustration, infographic, UI mockup).
- Generate a new image **guided by one or more reference images** for style, composition, subject, or character consistency (image-to-image).
- Produce several assets or variants for one task.

## When not to use (route elsewhere)
- **Editing an existing image** — remove background, erase/replace an object, repaint a masked region, upscale, or restore: use the dedicated tools `edit_image` (background removal), `image_erase`, `image_inpaint`, `image_upscale`, `image_restore`.
- Matching or extending an existing **SVG / vector / icon set** in the repo, or simple shapes / diagrams / wireframes that are better produced directly in SVG, HTML/CSS, or canvas.
- Any task where the user clearly wants deterministic code-native output instead of a generated bitmap.

## Decision tree

Decide two separate questions.

**1) Intent — generate vs edit**
- No source image, or images provided **only as references** (style / composition / subject) → **generate** with `generate_image` (pass the refs via `referenceImages`).
- Modify an existing image while preserving parts of it (remove background, erase, inpaint, upscale, restore) → **edit**: use the dedicated edit tool, not this one.
- Assume **generate** unless the user clearly wants to change an existing image.

**2) Execution — one asset vs many**
- One image per `generate_image` call.
- For **variants of one prompt**, use `count` (1–4).
- For **several distinct assets**, issue one `generate_image` call per asset — do not use `count` as a substitute for separate prompts.

## Calling generate_image

- `prompt` (required) — the image spec (see Shared prompt schema). The platform caps the prompt at **~1000 characters** (it is rejected above that); make it dense rather than long.
- `model` — optional. Leave unset and the platform recommends one (commonly `gpt-image-2` — strong typography and precise semantics) and offers the full usable list in the confirmation dialog. Only set it if the user named a specific model. The values below (aspect ratios, quality tiers, count, resolution, reference-image limits) are **per-model** — the dialog shows what the selected model actually supports, so treat the specifics here as `gpt-image-2`'s defaults, not universal limits.
- `aspectRatio` — one of `1:1` (default), `16:9`, `9:16`, `4:3`, `3:4`, `21:9`, `3:1` (gpt-image-2's supported ratios). Output is 1K resolution.
- `quality` — **only for models with quality tiers** (e.g. gpt-image-2: `low` default / `medium` / `high`; **cost rises steeply**, high ≈ 20× low). Models like nano-banana have **no** quality tiers and use `resolution` instead — the confirmation popup shows whichever applies to the selected model.
- `resolution` — **only for models with multiple resolutions** (e.g. nano-banana: `1K`/`2K`/`4K`). gpt-image-2 is 1K-only and exposes `quality` instead. Per-model; the popup offers the selected model's resolutions.
- `count` — 1–4 (default 1; clamped to the model's max). Only use >1 when the user explicitly wants multiple options — each extra image costs more credits.
- `negativePrompt` — what to avoid (e.g. "blurry, extra fingers, watermark, text").
- `style` — optional preset: `auto` (default), `photography`, `portrait`, `anime`, `oil_painting`, `watercolor`, `sketch`, `cartoon`, `flat`. Prefer describing the style inside the `prompt`; use this only when the user names a specific style.
- `seed` — integer for reproducible results (same seed + prompt → same image; useful when tweaking a prompt while keeping composition).
- `referenceImages` — array of image-to-image references; each a **local file path**, an http(s) URL, or a base64 data URL. The max count is **per-model** (5 for gpt-image-2; some models allow more) — the tool clamps to the selected model's limit. For an image the user uploaded, pass its **local file path** — the tool uploads it for you; never invent a URL. Each reference adds credits and routes to the model's image-edit variant.

After the tool returns URL(s), present or save them (see Output). Generation usually takes a few seconds up to about a minute; tell the user it is processing rather than assuming it failed.

## Transparent background

gpt-image-2 has **no native transparent-background mode**. To produce a transparent PNG:
1. Generate the subject with `generate_image` (optionally on a plain, uncluttered background, with crisp edges).
2. Pass the resulting image to the **`edit_image` tool** (background removal) → a transparent PNG cutout.

This is cleaner than chroma-keying. Do not try to fake transparency in the prompt, and do not claim the built-in tool outputs transparency directly.

## Prompt augmentation (specificity policy)

Reformat the user's request into a clear, production-oriented spec — make the goal more actionable, but **do not blindly add detail**.
- If the prompt is **already specific and detailed**, preserve that specificity and only normalize/structure it.
- If the prompt is **generic**, add tasteful augmentation only when it materially improves the output.

**Allowed:** composition/framing hints, polish-level / intended-use hints, practical layout guidance, reasonable scene concreteness that supports the stated request.
**Not allowed:** extra characters or objects not implied by the request; brand names, slogans, or palettes not implied; arbitrary placement the layout doesn't support.

## Use-case taxonomy (pick one slug)

Keep the slug consistent across prompts. For **generate** intents:
`photorealistic-natural`, `product-mockup`, `ui-mockup`, `infographic-diagram`, `scientific-educational`, `ads-marketing`, `productivity-visual`, `logo-brand`, `illustration-story`, `stylized-concept`, `historical-scene`.

For **edit** intents (`text-localization`, `precise-object-edit`, `lighting-weather`, `background-extraction`, `style-transfer`, `compositing`, `sketch-to-render`) — route to the dedicated edit tools instead of `generate_image`.

## Shared prompt schema

Use this labeled spec as scaffolding (use only the lines that help; render the final value as natural prose in `prompt`):

```
Use case: <taxonomy slug>
Asset type: <where the asset will be used>
Primary request: <user's main prompt>
Reference images: <Image 1: role; Image 2: role> (optional)
Scene/backdrop: <environment>
Subject: <main subject>
Style/medium: <photo / illustration / 3D / flat / etc>
Composition/framing: <wide/close/top-down; placement>
Lighting/mood: <lighting + mood>
Color palette: <palette notes>
Text (verbatim): "<exact text>"
Constraints: <must keep / must avoid>
```

For images with text (logos, posters, UI), quote the exact words verbatim and specify typography + placement; for tricky words, spell them out letter-by-letter and require verbatim rendering. For multi-image inputs, reference images by index and describe how each should be used.

## Examples

**Generate (hero):**
```
Use case: product-mockup
Asset type: landing-page hero
Primary request: a minimal hero of a ceramic coffee mug
Style/medium: clean product photography
Composition/framing: wide, with negative space for page copy
Lighting/mood: soft studio lighting
Constraints: no logos, no text, no watermark
```
→ `generate_image({ prompt: "<the spec above, as prose>", aspectRatio: "16:9", quality: "medium" })`

**Image-to-image (variation):** user uploaded `~/Desktop/cat.png` and wants "the same cat in a snowy scene":
→ `generate_image({ prompt: "the same cat sitting in fresh snow at dusk, soft winter light, photorealistic", referenceImages: ["~/Desktop/cat.png"] })`

## Output / save policy

`generate_image` returns image **URL(s)** — not a local file.
- **Preview / brainstorm**: present the URL(s) inline; nothing needs saving.
- **Project-bound asset**: download the chosen image into the workspace (e.g. `curl -o assets/hero.png "<url>"`) and wire it into the consuming code/references. **Never leave a project-referenced asset as only a remote URL.**
- **Do not overwrite** an existing asset unless the user asked for replacement — use a versioned sibling name such as `hero-v2.png`.
- Always report the final saved path(s), plus the model and key parameters used.

## Constraints
- gpt-image-2: 1K resolution only (no 2K/4K); aspect ratio limited to the seven listed; **no native transparency** (use `edit_image`).
- `count` is 1–4; `style` must be one of the presets above (omit for `auto`); `referenceImages` up to the selected model's limit (5 for gpt-image-2); prompt up to ~1000 characters.
- **Cost scales with `quality`, `count`, and the number of `referenceImages`** — keep all three minimal unless the user explicitly asks for more.
- One image concept per call; for unrelated images, call the tool again.
