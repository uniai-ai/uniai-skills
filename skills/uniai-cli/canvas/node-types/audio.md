# `audio` node

Generates audio — either **speech** (text-to-speech) or **music**, selected by `--mode`.

## Fields (`node create --type audio`)

| flag | → `data` | notes |
| --- | --- | --- |
| `--text` \| `--prompt` | `data.text` | the words to speak (TTS) or the music prompt; first present wins |
| `--model` | `data.model` | id from `uniai canvas model --node-type audio --mode <tts\|music>` |
| `--voice` | `data.voice` | voice id (TTS) |
| `--mode` | `data.mode` | `tts` or `music` — picks the sub-catalog/behavior |

## Typical use

```bash
# list TTS voices/models for the mode you want
uniai canvas model --node-type audio --mode tts

# a narration node
uniai canvas node create --type audio --mode tts \
  --text "Welcome to the cabin in the woods." \
  --model <ttsModelId> --voice <voiceId> < /dev/null
```

Key points:

- Pick `--model` (and `--voice` for TTS) from the catalog for the matching `--mode`; a voice from the
  wrong mode won't apply.
- To narrate text produced earlier, connect a `text` node into this audio node so its content flows in
  as the words.
