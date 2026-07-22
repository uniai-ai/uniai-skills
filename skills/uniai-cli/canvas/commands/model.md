# `uniai canvas model` — model catalog per node type

Lists the models available for a given node type, so you can pick a valid id to pass as
`node create --model <id>`. The catalog is the single source of truth — model ids change over time, so
**query it instead of guessing**.

Usage skeleton:
`uniai canvas model --node-type <text|image|video|audio|script|storyboard|video_clip> [--mode tts|music] [--json]`

- nodeType from `--node-type`, else `--type`, else positional `args[0]`. Missing → usage (exit 2).
- `--mode` is for the `audio` type to pick the sub-catalog: `tts` (speech) vs `music`.
- `GET /canvas/models?nodeType=<>&mode=<>` (mode sent only when given).
- Output: non-json → one `<canonicalId|id>\t<displayName|name>` per line; json →
  `{"ok":true,"models":[…]}`. Each model object also carries a `config` blob (JSONB passthrough — e.g.
  `maxCount`, `supportedAspectRatios`, duration ranges; shape varies per feature) and a `primaryChannel`
  pricing block — see [../model-schema/schema.md](../model-schema/schema.md) for the fields.

Notes:

- The first column (`canonicalId` / `id`) is exactly what you pass to `node create --model`.
- `script` resolves to text/LLM models; `storyboard` resolves to image models (they map to different
  features, so each returns only its own kind).
- `video_clip` is a timeline/edit node with **no generation models**: this command returns an empty
  list (`{"ok":true,"models":[]}`) — that's expected, not an error. Its editing capability is not
  exposed through the model catalog.

## Examples

```bash
# case 1: list image models, pick an id for --model
uniai canvas model --node-type image

# case 2: list TTS voices/models for an audio node
uniai canvas model --node-type audio --mode tts --json

# case 3: list video models with full schema
uniai canvas model --node-type video --json
```
