# `storyboard` node

Generates a **set of storyboard frames** (one image per shot). Shots come from an upstream `script`
node's `scenes[].imagePrompt` if connected; otherwise it makes `--shot-count` images derived from
`--prompt`. Images are generated **sequentially**, each **billed** via the image service. Output is
`data.imageUrls[]`.

## Fields (`node create --type storyboard`)

| flag | → `data` | notes |
| --- | --- | --- |
| `--prompt` | `data.prompt` | base prompt when there's no upstream script (each shot = `"<prompt> — shot N"`) |
| `--model` | `data.model` | image model id from `uniai canvas model --node-type storyboard` |
| `--shot-count` | `data.shotCount` | how many frames when deriving from `--prompt` (default 3, **max 6**); ignored when an upstream script provides scenes |

Output after running: `data.imageUrls[]` (one URL per successful shot; a shot that fails is skipped, the
node still completes as long as ≥1 succeeds).

## Typical use

```bash
# scene-driven: a script's scenes decide how many frames and their prompts
uniai canvas node create --type script --prompt "A three-shot product-ad storyboard" \
  | uniai canvas node create --type storyboard --model <imageModelId>

# standalone: fixed number of frames from one prompt
uniai canvas node create --type storyboard --prompt "moody cyberpunk alley, neon rain" \
  --model <imageModelId> --shot-count 4 < /dev/null
```

Key points:

- Connect a `script` node upstream for scene-driven frames (one image per scene, using each scene's
  `imagePrompt`). The frame count then follows the script's scenes, not `--shot-count`.
- Cost scales with the number of shots — keep it small unless asked.
