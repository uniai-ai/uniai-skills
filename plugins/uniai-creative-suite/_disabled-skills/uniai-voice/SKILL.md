---
name: uniai-voice
description: Convert text into natural-sounding spoken audio (text-to-speech / TTS) using UniAI voice models. Use this when the user asks to read text aloud, create a voiceover, generate narration, make an audiobook-style reading, or turn written text into speech (e.g. "make a voiceover", "narrate this", "read this aloud").
---

# UniAI Voice (Text-to-Speech)

Turn written text into spoken audio. This skill drives the `text_to_speech` tool (provided by the uniai MCP server) and routes it to UniAI's TTS models. Returns a URL to the generated audio.

## When to use this skill

Trigger on requests to speak text aloud, such as:

- "make a voiceover / narrate this / read this aloud / turn this text into speech"
- producing an audio reading of a script, paragraph, or message

Do **not** use it to compose music or a song (use the music tool instead), or to transcribe existing audio into text (use the speech-to-text tool instead).

## How to generate

Use the `text_to_speech` tool (from the uniai MCP server). If `text_to_speech` is not already among your available tools, first call `tool_search` to load it (search e.g. "text to speech"), then call it. If it still cannot be found after searching, tell the user that text-to-speech isn't available in this environment rather than guessing.

Call `text_to_speech` with these arguments:

- `text` (required, string) — the text to synthesize into speech, **up to 5000 characters**.
- `voice` (optional, string) — a voice id. Omit unless you know a valid voice id; a default voice is used otherwise. Do not invent voice ids.
- `format` (optional, enum) — `"mp3"` (default), `"wav"`, `"pcm"`, `"opus"`, `"aac"`, or `"flac"`.
- `rate` (optional, number) — speaking-rate multiplier from **0.5 (slow) to 2.0 (fast)**, default `1.0`.

After the tool returns a URL, present it to the user.

## Writing good input text

The synthesizer reads the `text` literally, so prepare it like a script:

1. **Write it the way it should be heard** — expand abbreviations and symbols the listener should hear as words ("3kg" → "three kilograms" if you want it spoken that way).
2. **Use punctuation for pacing** — commas and periods create natural pauses; break long sentences up.
3. **Match `rate` to the use** — slower (e.g. `0.85`) for clear narration or learning content, faster (e.g. `1.15`) for energetic promos.
4. **One language per call** generally reads most naturally; the default voice handles common languages.

Example: synthesizing a 30-second product intro at `rate: 0.95` for a calm, clear delivery.

## Constraints

- `text` must be non-empty and at most 5000 characters; split longer content into multiple calls.
- `rate` must be between 0.5 and 2.0.
- `format` must be one of `mp3`, `wav`, `pcm`, `opus`, `aac`, `flac`.
- Only set `voice` to a voice id you actually know is valid; otherwise omit it.
