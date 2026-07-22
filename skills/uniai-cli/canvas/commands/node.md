# `uniai canvas node` — create / query / edit nodes

A **node** is one vertex of the canvas DAG; each node generates one asset when the graph runs.
Subcommands: **`create`**, **`get`**, **`list`**, **`update`**, **`delete`**. A bare `node <id>` (no known
verb, no `--type`) is treated as `get <id>` (LibTV-style query).

Usage skeleton:
```
uniai canvas node create --type <text|image|video|audio|script|storyboard> \
  [--prompt … | --content … | --text …] [--model <id>] [--name <label>] [type-specific flags] \
  [--set "k=v,k2=v2"] [--x <n>] [--y <n>] [--width <n>] [--height <n>] [--key <name>] [--project <id>] [--json]
uniai canvas node get <nodeId> [--project <id>] [--json]
uniai canvas node list [--type <t>] [--project <id>] [--json]
uniai canvas node update <nodeId> --type <type> [same data flags as create] [--project <id>]
uniai canvas node delete <nodeId> [--prune-edges] [--project <id>]
```

- Project resolved from `--project` or `.uniai/project.json`.
- Backend (unified **art** canvas): `POST /art/projects/<id>/elements` (create), `GET /art/projects/<id>`
  (get/list read `elements`), `PATCH .../elements/<nodeId>` (update `data`), `DELETE .../elements/<nodeId>`.
- art elements are a positioned canvas — `create` also sets `x/y/width/height`.
  - Omit `--x` → auto-laid-out at **rightmost edge of existing elements + 60** (never overlaps,
    but everything lands on one long row). For multi-shot pipelines, prefer one row per shot:
    pass `--x` explicitly per column and `--y <shotIndex * 700>`.
  - **image/video cards size themselves**: the card frame is derived from the generation aspect
    ratio (long edge 560, e.g. 9:16 → 315×560). `--width/--height` on image nodes set the
    **generation resolution** (and imply `aspectRatio` when `--aspect-ratio` is omitted) — they do
    NOT set the card frame. Cards crop media that doesn't match their frame ratio, so this keeps
    the full picture visible.

## stdin auto-connect (and the standalone-create gotcha)

Before creating, `node create` reads **stdin** for upstream node ids:

- If stdin is a TTY → it returns immediately (no wait).
- Otherwise it reads all of stdin, parses each line as JSON, and collects every `nodeId` it finds. It
  then connects **each** collected upstream `→ this new node`, in order. A failed edge prints a `warn:`
  to stderr and continues.

This is what makes `(a && b) | c` fan upstream `a` and `b` into `c`, and also lets **`node list`** replay
existing nodes into a pipe (see Output and [../examples/pipes/README.md](../examples/pipes/README.md)).

> **Gotcha for non-interactive shells (e.g. an agent's shell): when you are NOT piping an upstream,
> redirect stdin from `/dev/null`** so the read can't stall:
> ```
> uniai canvas node create --type image --prompt "…" < /dev/null
> ```

## Fields set per `--type`

`node create`/`update` populate `data` for these types (other typed flags are ignored):

| `--type` | flags → `data` |
| --- | --- |
| `text` | `--content` \| `--text` \| `--prompt` → `data.content` |
| `image` | `--prompt`→`data.prompt`; `--negative-prompt`→`data.negativePrompt`; `--model`→`data.model`; `--aspect-ratio`→`data.aspectRatio` (**the field the executor actually uses for output shape**; `--width/--height` imply it when omitted, e.g. 720/1280 → `9:16`; neither given → 16:9 default); `--image-url`→`data.imageUrl` (hold an uploaded image as a source node); `--preset upscale\|three-view\|grid` → special image node |
| `video` | `--prompt`→`data.prompt`; `--model`→`data.model`; `--duration`→`data.duration`; `--aspect-ratio`→`data.aspectRatio`; `--first-frame`/`--reference-image`→`data.referenceImageUrl` (image-to-video); `--reference-audio`→`data.referenceAudioUrl`; `--ref-mode reference\|edit` (upstream video-as-reference mode) |
| `audio` | `--text` \| `--prompt` → `data.text`; `--model`→`data.model`; `--voice`→`data.voice`; `--mode`→`data.mode`. **Defaults to TTS (reads the text aloud)** — for background music / score / ambience you MUST add `--mode music` (with a music-style `--prompt`), or the run will literally narrate your music description as speech |
| `script` | `--prompt`→`data.prompt`; `--model`→`data.model` (LLM) |
| `storyboard` | `--prompt`→`data.prompt`; `--model`→`data.model` (image); `--shot-count`→`data.shotCount`; `--aspect-ratio`; `--width`/`--height` |

`--name <label>` (alias `--label`) sets `data.label` on **any** type — the addressable name used by
`--ref "name"` and `{{Node "name"}}`. Per-type details: [../node-types/README.md](../node-types/README.md).

> **`{{Node "name"}}` resolves ONLY among nodes already connected upstream.** It is not a magic
> lookup — with no edge, the placeholder goes to the model as literal text and the reference is
> silently lost. Always pass `--ref "name"` (auto-connects) on the same `node create`, or pipe the
> upstream node in. Run `uniai canvas diagnose` to catch orphan nodes before spending credits.

> These types are runnable by `uniai canvas run` (`script` writes a shot list, `storyboard` turns scenes
> into images, `video_clip` ffmpeg-merges upstream clips). `image_editor` is not yet executable.

## `--set` — pass any data field (escape hatch)

art's `node.data` is flat, so `--set "key=value,key2=value2"` writes arbitrary fields straight into
`data`, covering anything the typed flags don't (`count`, `quality`, `resolution`, `seed`, `modeType`, …).
Values are coerced: pure numbers → number, `true`/`false` → boolean, else string (so `9:16` stays a
string). `--set` is applied **after** typed flags, so on a key clash `--set` wins. Works on `create` and
`update`.

Two parsing limits to know:
- Pairs split on `,` — a **value cannot contain a comma** (put comma-bearing text in `--prompt`/typed
  flags instead).
- Number coercion is aggressive: `seed=007` → `7`, `x=1e3` → `1000`. If you need a digits-only
  **string** preserved verbatim, `--set` can't express that today — use a typed flag when one exists.

```bash
uniai canvas node create --type image --prompt "hero shot" --set "count=4,quality=high" < /dev/null
uniai canvas node update <imgNode> --type image --set "seed=42"
```

## Other flags

- `--x <n>` / `--y <n>` / `--width <n>` / `--height <n>`: canvas position/size — except on
  image/video nodes, where `--width/--height` mean **generation resolution** and the card frame is
  auto-derived from the aspect ratio (see above). The space form can't take a value starting with
  `-` (e.g. `--x -100` parses as a boolean → falls back to default); use the equals form for
  negatives: `--x=-100`.
- `--key <name>`: a label echoed back in the emitted `nodeKey` field for your own bookkeeping. **Not**
  sent to the backend, **not** used by the auto-connect reader.

## Query: `get` and `list`

- `node get <nodeId>` (or bare `node <id>`) → the node's `type`, `label`, whether it `hasResult`, its
  output `url` (if any), and full `data` (in `--json`). TTY: `node <id>\t<type>[\t"label"]\t<ready|empty>[\t<url>]`.
- `node list [--type <t>]` → all nodes (optionally filtered by type). **In a pipe / `--json` it emits one
  NDJSON line per node** (`{"ok":true,"nodeId":…,"type":…,"label":…,"hasResult":…,"url":…}`), so you can
  **replay existing nodes into `node create`** (its stdin reader consumes the `nodeId`s and auto-connects):
  ```bash
  # wire every existing image node into a new video_clip
  uniai canvas node list --type image | uniai canvas node create --type video_clip < /dev/null
  ```

## Create output

- Non-TTY stdout **or** `--json` → one NDJSON line:
  `{"ok":true,"nodeId":"<id>","type":"<type>","connectedFrom":["<srcId>",…]}`. `nodeKey` is added only
  with `--key`.
- Interactive TTY → `<nodeId>\t<type>[\t<key>][\t<- src1,src2]`.

There is **no single-node run**: `node create` never triggers generation. Build the graph, then execute
it with [`uniai canvas run`](./run.md) (`run --only <id>` runs just that node + any missing upstreams).

## Delete a node (and its edges)

- `uniai canvas node delete <nodeId>` — deletes the element. art stores edges in
  `canvasState.connections` (JSON), so they are **not** auto-removed; the dangling edges will show up in
  `uniai canvas diagnose` as `orphan_edge`.
- `uniai canvas node delete <nodeId> --prune-edges` — also removes every edge touching the node, keeping
  the graph clean.

## Examples

```bash
# standalone text node (redirect stdin since we're not piping)
uniai canvas node create --type text --content "A cozy cabin at dawn, cinematic" < /dev/null

# chain text → video by piping (auto-connects the text node into the video node)
uniai canvas node create --type text --content "storm rolling over the cabin" \
  | uniai canvas node create --type video --prompt "slow push-in, 4s" --model <videoModelId>

# inspect a node, then delete it and clean its edges
uniai canvas node get <nodeId>
uniai canvas node delete <nodeId> --prune-edges
```
