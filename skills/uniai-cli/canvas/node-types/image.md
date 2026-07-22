# `image` node

Generates an image. Its output image flows into a downstream node (e.g. a `video` node's first frame)
along the edge.

## Fields (`node create --type image`)

| flag | → `data` | notes |
| --- | --- | --- |
| `--prompt` | `data.prompt` | what to draw |
| `--negative-prompt` | `data.negativePrompt` | what to avoid (optional) |
| `--model` | `data.model` | id from `uniai canvas model --node-type image` |
| `--width` | `data.width` | output width in px (optional) |
| `--height` | `data.height` | output height in px (optional) |

## Typical use

```bash
# list models, then create with an explicit one
uniai canvas model --node-type image
uniai canvas node create --type image \
  --prompt "a lone cabin under aurora, wide establishing shot, photoreal" \
  --negative-prompt "text, watermark, blur" \
  --model <imageModelId> --width 1280 --height 720 < /dev/null
```

Key points:

- Aspect ratio is controlled here by explicit `--width`/`--height`; omit them for the model default.
- To drive the prompt from a prior step, connect a `text` node into this image node (the upstream text
  becomes the prompt) instead of writing a `{{Node …}}` reference.
- `--image-url <url>` makes an image node carry an existing/uploaded image (upload first with
  [`uniai canvas upload`](../commands/upload.md)). Connected to a downstream `video` node, that image
  becomes its first frame. For one-shot image-to-image from a local file, the top-level
  `uniai image generate --reference` is still the simpler route.
