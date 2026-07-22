# `video` node

Generates a video clip. A common chain is `text → image → video`, where the upstream image becomes the
video's first frame (wired by the edge, resolved server-side).

## Fields (`node create --type video`)

| flag | → `data` | notes |
| --- | --- | --- |
| `--prompt` | `data.prompt` | describe the motion/scene (always useful) |
| `--model` | `data.model` | id from `uniai canvas model --node-type video` |
| `--duration` | `data.duration` | clip length (seconds); allowed range depends on the model |
| `--aspect-ratio` | `data.aspectRatio` | e.g. `16:9`, `9:16`, `1:1` (model-dependent) |

## Typical use

```bash
# list video models (see each model's modes/durations/ratios), then create
uniai canvas model --node-type video --json
uniai canvas node create --type video \
  --prompt "slow cinematic push-in, gentle snowfall" \
  --model <videoModelId> --duration 4 --aspect-ratio 16:9 < /dev/null

# chain: image → video (the image node feeds the first frame via the edge)
uniai canvas node create --type image --prompt "cabin at dusk, wide" --model <imageModelId> \
  | uniai canvas node create --type video --prompt "push in slowly, 4s" --model <videoModelId>
```

Key points:

- `--duration` / `--aspect-ratio` must be values the chosen model supports — check the catalog schema
  ([../model-schema/schema.md](../model-schema/schema.md)) when unsure; out-of-range values can make the
  node fail at run time.
- For image-to-video, either connect an upstream `image` node (its image flows in as the first frame)
  **or** pass `--first-frame <url>` / `--reference-image <url>` directly (upload a local file first with
  [`uniai canvas upload`](../commands/upload.md)); `--reference-audio <url>` adds an audio reference.
  For a quick one-shot image-to-video from a local file, the top-level
  `uniai video generate --first-frame <path>` is still simpler.
