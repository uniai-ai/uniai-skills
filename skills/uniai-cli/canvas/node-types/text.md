# `text` node

An LLM text node. Use it to write copy, a prompt, narration, or a script fragment that downstream nodes
consume (its `content` flows into a downstream node's prompt along the edge).

## Fields (`node create --type text`)

| flag | → `data` | notes |
| --- | --- | --- |
| `--content` \| `--text` \| `--prompt` | `data.content` | the text/instruction; first one present wins |

No model flag is wired into `data` for `text` via the builder; the platform uses a default text model.
List text models with `uniai canvas model --node-type text` if you need to know what's available.

## Typical use

```bash
# standalone (redirect stdin when not piping)
uniai canvas node create --type text \
  --content "Write a 1-sentence cinematic prompt for a storm over a cabin." < /dev/null

# as the head of a chain: text → image
uniai canvas node create --type text --content "a lone cabin under aurora, wide shot" \
  | uniai canvas node create --type image --prompt "render it photorealistically"
```

Key points:

- Downstream nodes receive this node's `content` as input via the edge — keep it self-contained.
- Don't try to reference other nodes with `{{Node …}}`; wire edges instead (see
  [README.md](./README.md)).
