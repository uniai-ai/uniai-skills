# Reading the model catalog (`uniai canvas model --node-type <type> --json`)

`uniai canvas model --node-type <type> --json` returns `{"ok":true,"models":[ … ]}`, one object per
available model. The catalog is the **single source of truth** for which models exist and what each
supports — read it instead of hard-coding ids or parameter ranges. Adding models is a backend-only
change, so what you pass to `--model` is whatever the catalog currently reports.

## Fields on each model object

| field | meaning |
| --- | --- |
| `canonicalId` | **the id you pass to `node create --model`** (first column in the non-json output) |
| `displayName` | human label |
| `description` | optional blurb |
| `category`, `modality`, `tier` | classification (e.g. modality `image`/`video`/…) |
| `acceptedInputTypes` | input modalities the model accepts (e.g. `text`, `image`) |
| `modelFamily`, `inputType`, `logoUrl` | optional metadata |
| `isDefault`, `isEnabled`, `sortOrder` | catalog flags (`isDefault` = the platform default for that type) |
| `contextWindow` | context size in tokens (text models) |
| `config` | **JSONB blob of model-specific capabilities** — e.g. `maxCount`, `supportedAspectRatios`, duration ranges. Shape varies per feature; inspect it to learn what params are valid. |
| `primaryChannel` | pricing info: `pricingModel`, `inputPrice`, `outputPrice`, `fixedPrice?`, `pricePerSecond?`, `pricePerChar?`, `markup`, `priceModifiers?` |

## How to use it

1. **Pick a model id:** read `canonicalId`. Omit `--model` entirely to take the type's `isDefault`.
2. **Find valid parameters:** look inside `config` for the model you chose — e.g. `supportedAspectRatios`
   tells you what `--aspect-ratio` values are legal for a `video` node; a duration range tells you what
   `--duration` to pass. Passing an unsupported value can make the node fail at run time.
3. **Sanity-check cost:** `primaryChannel` carries the pricing basis (per-second for video, per-char for
   TTS, fixed for image, etc.). The authoritative cost still comes from the run estimate
   ([../commands/run.md](../commands/run.md)) — `primaryChannel` is just for understanding the basis.

> The `config` shape is **not** a fixed schema across types — don't assume specific nested keys exist.
> Read the actual `--json` for the model in hand and branch on what's present.

## Example

```bash
# inspect a video model's capabilities before creating the node
uniai canvas model --node-type video --json
# → find the model, read config.supportedAspectRatios / duration range, then:
uniai canvas node create --type video --model <canonicalId> \
  --aspect-ratio 16:9 --duration 4 --prompt "…" < /dev/null
```
