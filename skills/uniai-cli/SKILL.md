---
name: uniai-cli
description: Call UniAI platform AI features from the terminal with the `uniai` CLI — text chat, image generation & editing, video generation, text-to-speech (TTS) and speech recognition (STT), OCR, web search, code generation, and credit-balance checks. Use whenever the user wants to create an image or video, synthesize or transcribe speech, read text out of an image, search the web for current information, generate code, chat with a model, or check their UniAI credits — and the `uniai` command is available on PATH.
---

# UniAI CLI

The `uniai` command calls UniAI platform AI features directly from the terminal. Every command
accepts `--json` and returns a structured envelope, so prefer `--json` and read the fields
(`ok`, `text`, `url`, `credits`, `error`) instead of scraping prose.

## When to use this skill

Reach for `uniai` when the user wants any of: an image, a video, speech audio (TTS), a transcript
of audio (STT), text read out of an image (OCR), a web search for up-to-date information, generated
code, a quick model chat, or their credit balance — and `uniai` is installed.

## Prerequisites

- `uniai --version` must succeed. If it is missing, install with `npm i -g @uniai-ai/cli` (npm only;
  do not use pnpm/yarn for this), or have the user read the package's `install.md`.
- Auth: needs a UniAI Personal Access Token (PAT, starts with `uap_`). Probe with `uniai auth status`
  (prints a masked token). If it is not configured, first tell the user to create a PAT at
  <https://www.uniai.ai> → Personal Center → Security tab → Personal Access Tokens → Generate, then
  offer **two ways to log in** and let them choose:
  - **(A) you do it** — they paste the token into the chat and you run `uniai auth login --token
    <pasted_pat>` yourself via your shell/terminal tool.
  - **(B) they do it** — they run `uniai auth login --token <pat>` themselves in their own terminal,
    so the token never passes through the chat (prefer this if they are security-conscious).
  After either path, verify with `uniai auth status`. Security: never echo the token back in your
  prose replies — report only the masked value.
- Before a paid generation (image/video/speech), you may check budget first with
  `uniai usage --json` and read `credits.total`.

## Commands

```bash
uniai chat "<message>" --json
uniai image generate "<prompt>" [--model <id>] [--aspect-ratio 1:1|16:9|9:16|4:3|3:4|21:9|3:1] [--count <n>] [--quality low|medium|high] [--reference <path|url>[,...]] [--download out.png] --json
uniai image models --json     # list available image models + their supported params
uniai image edit --image <url> [--output-format png|jpg|webp] [--download out.png] --json
uniai video generate "<prompt>" [--model <id>] [--aspect-ratio 16:9|9:16|1:1] [--duration <2-15>] [--first-frame <img>] [--reference <img,..>] [--source-video <vid>] [--download out.mp4] --json
uniai video models --json     # list available video models + their modes/durations/resolutions
uniai speech synthesize "<text>" [--voice <id>] [--format mp3|wav] [--download out.mp3] --json
uniai speech recognize <audio: path|url> [--language auto|zh|en|ja|ko] --json
uniai ocr <image: path|url> --json
uniai search "<query>" [--limit 1-20] --json
uniai code "<description>" --language <python|typescript|...> --json
uniai usage --json            # credit balance (alias: uniai quota)
```

For media commands, pass `--download <file>` to save the result locally; report the saved path to
the user. Run `uniai <command> --help` for the full options of any single command.

**Image-to-image (from an uploaded/existing photo):** when the user wants a new image based on a photo
they gave you — e.g. "full-body shot of this person", "change the clothing", "same character, new
pose", "make a variation of this" — use `uniai image generate "<prompt>" --reference <path>` and pass
the photo's **local file path** (the tool uploads it for you; up to 5, comma-separated). Do NOT use
`uniai image edit` for that — `edit` only sharpens/feathers edges or processes the background of a URL,
it cannot follow a prompt or change content.

**Choosing model / parameters:** the CLI does not pop confirmation dialogs — it passes only the flags
you give and uses the platform-recommended model + parameters for everything else. So if the user cares
about the model, aspect ratio, count, or quality, ask them (or run `uniai image models` to show the
options), then pass the matching flags (`--model`, `--aspect-ratio`, `--count`, `--quality`). If they
don't care, just generate; sensible defaults are used. (No need to re-implement a selection flow — the
recommendation/confirmation logic lives in the shared core.)

**Video from an image / clip (animate, edit, extend):** for `uniai video generate`, the mode is
auto-derived from the media you attach — `--first-frame <img>` animates a photo (image-to-video),
`--first-frame` + `--last-frame` interpolates first→last, `--reference <img,..>` does reference-to-video,
`--source-video <vid>` edits/restyles a clip, `--continuation-video <vid>` extends one; none = text-to-video.
Pass the user's uploaded file's **local path** (it is uploaded for you). A prompt is always required
(describe the motion/scene). Run `uniai video models` to see which models support which modes. The same
`--model` / `--aspect-ratio` / parameter logic as image applies.

## Output contract

- success: `{"ok":true,"text":"...","url":"<media url, when applicable>"}`
- failure: `{"ok":false,"error":"..."}`
- exit codes: `0` success · `1` runtime / auth / network error · `2` invalid usage

On `out of credits`, tell the user to top up in the UniAI web console. On an auth failure, have them
re-run `uniai auth login --token uap_...`. On a forbidden/scope error for `usage`, the PAT needs the
`read:credits` scope.
