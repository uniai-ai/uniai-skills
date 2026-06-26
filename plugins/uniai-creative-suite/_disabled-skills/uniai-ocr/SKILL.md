---
name: uniai-ocr
description: Extract text from an image (OCR / optical character recognition) using UniAI. Use this when the user wants to read or pull text out of a picture, screenshot, scanned document, receipt, photo, or form (e.g. "OCR this", "extract text from image", "read the text in this screenshot", "what does this document say").
---

# UniAI OCR (Image Text Recognition)

Read text out of an image. This skill drives the `ocr` tool (provided by the uniai MCP server). It returns the recognized text synchronously.

## When to use this skill

Trigger on requests to get the text contained in an image, such as:

- "OCR this / extract the text from this image / read the text in this screenshot / what does this receipt say"

Use it for reading text from images — screenshots, scans, receipts, photos of documents or signs. For transcribing **audio** into text, use the speech-to-text tool instead.

## How to generate

Use the `ocr` tool (from the uniai MCP server). If `ocr` is not already among your available tools, first call `tool_search` to load it (search e.g. "ocr / read text from image"), then call it. If it still cannot be found after searching, tell the user that OCR isn't available in this environment rather than guessing.

Call `ocr` with this argument:

- `image` (required, string) — the image to read text from. Accepts **a local file path, an http(s) URL, or a base64 data URL**. The image must be **PNG, JPEG, or WebP, up to 10MB**.

The tool returns the recognized text directly (and notes a detected language when available). If no text is found, it reports that no text was detected.

## Getting accurate recognition

There is no prompt to tune — recognition quality depends on the input image:

1. **Use a clear, high-resolution image** — crop to just the text region when possible; blurry or low-resolution images recognize poorly.
2. **Keep text upright and well-lit** — straighten skewed scans and avoid heavy glare or shadows.
3. **Respect the limits** — convert anything outside PNG/JPEG/WebP first, and keep files under 10MB.
4. **Pass the image directly** — a local path works (auto-handled); you don't need to upload it yourself first.

## Constraints

- `image` is required and must be PNG, JPEG, or WebP, at most 10MB.
- This tool only reads text; it does not edit images or translate the extracted text (do translation as a separate step if asked).
- Recognition runs synchronously and returns the text in one response.
