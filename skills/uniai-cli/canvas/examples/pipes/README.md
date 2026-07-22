# Pipes — NDJSON auto-wiring (`(a && b) | c`)

The canvas CLI uses ordinary shell pipes to wire edges. There's no special syntax in the CLI itself —
the shell does the `&&` / `|` / `()`, and `node create` cooperates via NDJSON.

## The contract

- Every `node create` whose **stdout is not a TTY** (i.e. it's in a pipe) prints exactly one NDJSON
  line containing its new `nodeId` (plus `type`, `nodeKey`, `connectedFrom`).
- A `node create` whose **stdin is not a TTY** reads all of stdin, finds every `nodeId` in it, and
  connects **each** of those upstream nodes `→ the node it's about to create`, in order.

So piping = "collect every upstream `nodeId` on stdin and fan them into the new node."

```bash
# linear: text → image (one edge)
uniai canvas node create --type text --content "a storm over the cabin" \
  | uniai canvas node create --type image --model <imageModelId>

# fan-in: (a && b) | c  →  edges a→c and b→c
( uniai canvas node create --type image --prompt "clip A keyframe" --model <m> \
  && uniai canvas node create --type image --prompt "clip B keyframe" --model <m> ) \
  | uniai canvas node create --type video --prompt "cut between A and B" --model <videoModelId>
```

In the fan-in form, `&&` makes the shell run A then B and concatenate their NDJSON; the subshell `()`
groups them so both lines reach `c`'s stdin; `c` connects both into itself.

## Rules & gotchas

- `&&` (not `;` or `&`) keeps order deterministic and stops if an upstream create fails.
- You do **not** need `--json` for pipes to work — non-TTY stdout already emits NDJSON. (`--json` just
  forces it on a TTY too.)
- Only `node create` emits `nodeId`, and `nodeId` is the only field the reader consumes. `--key` adds a
  `nodeKey` label for your own logs; it is not used for wiring.
- For a **standalone** node (no upstream), don't pipe — redirect `< /dev/null` so the stdin read can't
  stall (see [../../commands/node.md](../../commands/node.md)).
- A failed edge during fan-in prints a `warn:` to stderr and continues; the node is still created.
- Building a big DAG in one pipeline gets unreadable fast — for anything beyond a couple of fan-ins,
  create nodes in separate steps and wire them with explicit `uniai canvas connect` calls.
