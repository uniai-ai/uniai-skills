# `uniai canvas upload` — local file / URL → hosted asset URL

`upload` turns a local file (or an existing URL) into a stable hosted asset URL on the UniAI platform.

Usage skeleton: `uniai canvas upload <path|url> [--kind image|video|audio] [--node] [--name <label>] [--json]`

- input: positional `args[0]` (or `--file`). Missing → usage (exit 2).
- `--kind`: `image` (default), `video`, or `audio`. Any other value → usage (exit 2).
- Behavior: an `http(s)` URL is returned **as-is** (no re-upload); a local path / data URL is uploaded
  to the matching endpoint and the hosted URL is returned. A local file that doesn't exist → an
  actionable error (pass a real path or a URL — don't pass the path of a file you only *described*).
- Output (URL mode): json or non-TTY stdout → `{"ok":true,"url":"<url>","kind":"<kind>"}`; TTY → the bare `<url>`.

## `--node` — upload straight into a canvas node

By default `upload` only returns a URL (which you then attach via `node create`). With `--node` it also
**creates a resource node** of the matching type (`image`/`video`/`audio`) carrying the uploaded `url`
(and `assetId` for web preview when the file was uploaded, not a pass-through URL). Because the node
already has a result, `run` treats it as `cached` (never re-generated, zero credits). It emits NDJSON so
you can pipe it straight into the graph:

- Output (`--node`): json / non-TTY → `{"ok":true,"nodeId":"<id>","type":"<kind>","url":"<url>","kind":"<kind>"}`;
  TTY → `<nodeId>\t<kind>\t<url>`.
- `--name <label>` sets the node's `data.label`; `--x`/`--y` position it (else auto-laid-out).

```bash
# upload a clip as a video node, then compose it
uniai canvas upload ./refs/intro.mp4 --kind video --node \
  | uniai canvas node create --type video_clip < /dev/null
```

## Feeding an uploaded asset into the canvas

`upload` gives you a hosted URL; attach it to a node like this:

- **As a source image** (then chain it): `uniai canvas node create --type image --image-url <url>` —
  the image node carries the URL and, when connected to a downstream `video` node, becomes that video's
  first frame (image-to-video).
- **Directly as a video's first frame / reference**:
  `uniai canvas node create --type video --first-frame <url> --prompt "…"` (or `--reference-image`),
  and `--reference-audio <url>` for an audio reference. See [node.md](./node.md).

```bash
# upload → use as a video first frame in one flow
FRAME=$(uniai canvas upload ./refs/cabin.png --kind image --json | python3 -c 'import sys,json;print(json.load(sys.stdin)["url"])')
uniai canvas node create --type video --first-frame "$FRAME" --prompt "slow push-in, 4s" --model <videoModelId> < /dev/null
```

## Examples

```bash
# case 1: upload a local image, capture the hosted URL
uniai canvas upload ./refs/character.png --kind image --json

# case 2: a URL passes through unchanged
uniai canvas upload https://example.com/clip.mp4 --kind video
```
