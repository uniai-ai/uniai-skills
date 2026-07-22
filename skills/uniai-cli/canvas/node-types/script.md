# `script` node

An LLM writes a **shot-by-shot script** from a brief. The run calls a text/LLM model and stores both
the raw text and a structured `scenes[]` (each with `description`, `imagePrompt`, `durationSec`,
`voiceover`). A downstream `storyboard` node turns those scenes into images. **Billed** as a text/LLM
call (deducted on success).

## Fields (`node create --type script`)

| flag | → `data` | notes |
| --- | --- | --- |
| `--prompt` | `data.prompt` | the brief; if a `text` node is connected upstream, its content is used as the brief instead |
| `--model` | `data.model` | LLM id from `uniai canvas model --node-type script` (omit for the default) |

Output after running: `data.content` (raw script) + `data.scenes[]` (parsed; empty if the model didn't
return valid JSON — the raw content is still kept).

## Typical use

```bash
uniai canvas model --node-type script        # pick an LLM id
# brief → script → storyboard (script's scenes drive the storyboard frames)
uniai canvas node create --type text --content "A shiba inu detective works a missing-person case in rainy neon Tokyo, cyberpunk, 3 shots" \
  | uniai canvas node create --type script --model <llmId> \
  | uniai canvas node create --type storyboard --model <imageModelId>
```

Key points:

- Connect a `text` node upstream to supply the brief, or pass `--prompt` directly.
- The model is asked for strict JSON `{"scenes":[{description,imagePrompt,durationSec,voiceover}]}`;
  `scenes[].imagePrompt` is what a downstream `storyboard` uses per shot.
