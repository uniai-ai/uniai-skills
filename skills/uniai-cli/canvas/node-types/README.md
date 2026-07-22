# Canvas node types

Each node has a `--type`. The model catalog (`uniai canvas model --node-type <type>`) recognizes the
seven node-type names below — plus an `image_editor` alias that resolves to image models (same behavior
as `image`). All seven are **runnable** (`uniai canvas run` generates them); `image_editor` is the only
type not yet executable. Use this table to know what each one does.

| `--type` | Runnable | Doc | Notes |
| --- | --- | --- | --- |
| `text` | ✅ (source, free) | [text.md](./text.md) | A source node — your written text; drives downstream prompts. Not billed. |
| `image` | ✅ | [image.md](./image.md) | Image generation |
| `video` | ✅ | [video.md](./video.md) | Video generation (image upstream → first frame) |
| `audio` | ✅ | [audio.md](./audio.md) | TTS speech / music (`--mode tts\|music`) |
| `script` | ✅ | [script.md](./script.md) | LLM writes a shot-by-shot script (`scenes[]`); billed as a text/LLM call |
| `storyboard` | ✅ | [storyboard.md](./storyboard.md) | One image per upstream script scene (or `--shot-count`); billed per image |
| `video_clip` | ✅ (composite, free) | [video-clip.md](./video-clip.md) | ffmpeg-merges upstream video clips (+ optional audio) into one; **no AI cost** |
| `image_editor` | ⛔ not yet | — | Reserved; not yet executable in `run` |

`text` and `video_clip` cost no credits (source / local ffmpeg composition); `image`/`video`/`audio`/
`script`/`storyboard` each bill via their underlying service. The run estimate counts only the billable
ones (see [../commands/run.md](./../commands/run.md)).

## How parameters and data flow work

Two distinct kinds of input feed a node:

1. **Parameters you set at create time** — the `--prompt` / `--model` / size / duration / voice flags,
   which land in the node's `data` (see each type's doc). These are the knobs for *that* node.
2. **Upstream outputs that arrive via edges** — when you `connect A → B` (or pipe), the run feeds A's
   output into B's matching input server-side (e.g. an upstream image's URL becomes a downstream video
   node's first frame; an upstream text node's content becomes a downstream node's prompt). You don't
   spell this out per-field; the backend maps it from the edge.

   To **override or extend** the default per-field mapping, set an explicit mapping on the edge:
   `uniai canvas connect <src> <tgt> --map "fromField:toField"` (or edit it in the web node panel). The
   run then feeds upstream `data.<fromField>` into downstream param `<toField>` — e.g. route a `script`
   node's `content` into a downstream `prompt` (which the default rule doesn't do). See
   [../commands/connect.md](../commands/connect.md).

> There is **no `{{Node "name"}}` placeholder** that works end-to-end right now — writing one into a
> prompt just sends the literal text. Express "use the previous step's output" by **drawing the edge**
> (and, if the default field routing isn't what you want, `connect --map fromField:toField`) — not by
> referencing node names inside the prompt.

## Picking a model

Pass `--model <id>` using an id from `uniai canvas model --node-type <type>` (the first column).
Omitting `--model` lets the platform pick a sensible default for that type. See
[../model-schema/schema.md](../model-schema/schema.md) for reading a model's input schema (modes,
slots, allowed ranges).
