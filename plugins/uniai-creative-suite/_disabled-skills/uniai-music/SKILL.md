---
name: uniai-music
description: Generate original music or a song from a text description using UniAI music models. Use this when the user asks to create background music, a BGM track, a soundtrack, a jingle, an instrumental, a melody, or a full song with lyrics (e.g. "make background music", "compose a jingle", "write a song about ...").
---

# UniAI Music Generation

Turn a text description into generated audio. This skill drives the `generate_music` tool (provided by the uniai MCP server) and routes it to UniAI's music models. Generation typically takes 30–120 seconds and returns a URL to the audio.

## When to use this skill

Trigger on requests to produce music or a song from text, such as:

- "make / generate / compose background music, a soundtrack, a jingle, or a melody"
- "write a song about ..." (with or without lyrics)

Do **not** use it for spoken narration or reading text aloud (use the text-to-speech tool instead), or for transcribing existing audio.

## How to generate

Use the `generate_music` tool (from the uniai MCP server). If `generate_music` is not already among your available tools, first call `tool_search` to load it (search e.g. "generate music"), then call it. If it still cannot be found after searching, tell the user that music generation isn't available in this environment rather than guessing.

Call `generate_music` with these arguments:

- `prompt` (required, string) — a natural-language description of the style and mood, **10–300 characters**. E.g. "upbeat electronic dance track" or "calm lo-fi piano".
- `lyrics` (optional, string) — song lyrics to be sung, **10–600 characters**. Omit this for **instrumental** music — a neutral placeholder is sent so the model leans instrumental. Provide it when the user wants sung vocals.
- `model` (optional, string) — UniAI music model id. Leave unset to use the platform default; do not invent ids.
- `format` (optional, enum) — `"mp3"` (default), `"wav"`, or `"pcm"`.

After the tool returns a URL, present it to the user. Tell the user it is processing rather than assuming failure — music generation usually takes 30–120 seconds.

## Writing a good music prompt

A strong music prompt names the musical attributes the model should match:

1. **Genre / style** — "lo-fi hip hop", "orchestral cinematic", "synthwave", "acoustic folk".
2. **Mood / energy** — "calm and reflective", "upbeat and energetic", "tense", "uplifting".
3. **Instrumentation** — "warm piano and soft pads", "driving 808 bass and crisp hats".
4. **Use / tempo** — "slow background music for a product demo", "fast jingle for an ad".

For a sung song, put the words in `lyrics` (not in `prompt`) and use `prompt` for the musical style.

Example prompt:

> Calm lo-fi hip hop with warm piano, soft vinyl crackle, and a mellow boom-bap beat — relaxing background music for studying.

## Constraints

- `prompt` must be 10–300 characters; `lyrics`, if provided, must be 10–600 characters.
- Omitting `lyrics` requests instrumental music; the exact instrumental result depends on the upstream model.
- `format` must be one of `mp3`, `wav`, `pcm`.
- One music concept per call; for variations, call the tool multiple times.
