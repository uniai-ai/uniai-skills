---
name: uniai-transcribe
description: Transcribe spoken audio into written text (speech-to-text / STT) using UniAI. Use this when the user wants to transcribe a recording, voice memo, voice message, podcast clip, or audio/video file into text (e.g. "transcribe this audio", "transcribe the video", "turn this voice message into text", "what is said in this recording").
---

# UniAI Transcribe (Speech-to-Text)

Turn spoken audio into written text. This skill drives the `speech_to_text` tool (provided by the uniai MCP server). It returns the transcript synchronously.

## When to use this skill

Trigger on requests to get the words spoken in an audio (or the audio track of a video), such as:

- "transcribe this audio / transcribe the recording / turn this voice message into text / what is said in this clip"

Use it for converting **audio** into text. For reading text **out of an image** (a screenshot or scan), use the OCR tool instead. For turning text **into** speech, use the text-to-speech tool.

## How to generate

Use the `speech_to_text` tool (from the uniai MCP server). If `speech_to_text` is not already among your available tools, first call `tool_search` to load it (search e.g. "transcribe / speech to text"), then call it. If it still cannot be found after searching, tell the user that transcription isn't available in this environment rather than guessing.

Call `speech_to_text` with these arguments:

- `audio` (required, string) — the audio to transcribe. Accepts **a local file path, an http(s) URL, or a base64 data URL**. Supported formats: **MP3, WAV, WebM, OGG, M4A, up to 10MB**.
- `language` (optional, enum) — spoken-language hint: `"auto"` (default, auto-detect), `"zh"`, `"en"`, `"ja"`, or `"ko"`.

The tool returns the transcript text directly. If no speech is detected, it reports that.

## Getting an accurate transcript

There is no prompt to tune — accuracy depends on the audio and the language hint:

1. **Set `language` when you know it** — passing `"zh"` / `"en"` / `"ja"` / `"ko"` is more reliable than `"auto"` for single-language audio.
2. **Use clean audio** — less background noise and clear speech transcribe far better.
3. **Respect the limits** — convert to a supported format (MP3/WAV/WebM/OGG/M4A) and keep files under 10MB; split or extract a clip from long recordings first.
4. **For a video**, extract or point at its audio track — this tool reads audio, not video frames.

## Constraints

- `audio` is required and must be MP3, WAV, WebM, OGG, or M4A, at most 10MB.
- `language` must be one of `auto`, `zh`, `en`, `ja`, `ko`.
- This tool only produces a plain transcript; it does not translate or summarize (do that as a separate step if asked).
- Transcription runs synchronously and returns the text in one response.
