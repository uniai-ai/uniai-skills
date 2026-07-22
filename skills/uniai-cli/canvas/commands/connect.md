# `uniai canvas connect` / `disconnect` — wire and unwire edges

`connect` adds a directed edge `source → target` between two existing nodes. Edges are how data flows:
at run time the source node's output is fed into the target node's matching input (see
[../node-types/README.md](../node-types/README.md) and the data-flow note in the top-level SKILL.md).

You often don't need `connect` directly — `node create` reading piped upstream NDJSON auto-wires edges
for you (see [node.md](./node.md) and [../examples/pipes/README.md](../examples/pipes/README.md)). Use
`connect` when you build nodes separately and wire them afterward.

Usage skeleton:
`uniai canvas connect <sourceNodeId> <targetNodeId> [--project <id>] [--json]`

- source: positional `args[0]` (or `--source` / `--from`). target: positional `args[1]` (or
  `--target` / `--to`). Either missing → usage (exit 2).
- Project resolved from `--project` or `.uniai/project.json`.
- Backend: the unified **art** canvas has no dedicated connect endpoint — edges live in
  `project.canvasState.connections` (JSON). The CLI does read-modify-write: `GET /art/projects/<id>` →
  append `{id, sourceId, targetId, sourcePort:'output', targetPort:'input'}` → `PATCH /art/projects/<id>`
  with the full connections array.
- Output: non-json → `<connectionId>\t<src> -> <target>`; json →
  `{"ok":true,"connectionId":…,"sourceNodeId":…,"targetNodeId":…}`.

> **No uniqueness enforcement (art):** connecting the same `(source, target)` twice **appends a second
> edge** (each with its own id). If you re-wire, `disconnect` the old edge first, or you'll get duplicate
> connections (harmless at run time — the upstream is just resolved once — but noisy).

> **`--map` is ignored on the art canvas.** Field-level data mapping (`connect --map from:to`) was a
> video-agent feature; art has no `dataMapping` on connections, so `--map` is accepted but a note is
> printed and it has no effect. Run-time wiring uses the fixed default rule (text `content` → prompt;
> image `url`/`imageUrl` → first frame / reference; audio → reference; script/storyboard read their own
> way). To feed a `script`'s text into a downstream `prompt`, put the text in the node's `--prompt` or use
> `{{Node "name"}}` references (see [node-reference.md](../node-reference.md) if present).

## `disconnect` — remove an edge

`uniai canvas disconnect <sourceNodeId> <targetNodeId>` removes that directed edge (all copies, if
duplicated). `uniai canvas disconnect <nodeId> --all` removes **every** edge touching the node (source or
target) — handy before deleting a node, or use `node delete <id> --prune-edges` to do both at once.

- Same read-modify-write on `canvasState.connections`; removing 0 edges is a no-op success (idempotent).
- Output: non-json → `N edge(s) removed …`; json → `{"ok":true,"removed":N,…}`.

```bash
uniai canvas disconnect <textNodeId> <imageNodeId>     # drop one edge
uniai canvas disconnect <imageNodeId> --all            # drop all edges on a node
```

## Examples

```bash
# wire an existing text node into an existing image node
uniai canvas connect <textNodeId> <imageNodeId>

# fan two upstream nodes into one downstream node
uniai canvas connect <clipA> <renderNode>
uniai canvas connect <clipB> <renderNode>

# re-wire: remove the wrong edge, add the right one
uniai canvas disconnect <clipA> <renderNode>
uniai canvas connect <clipB> <renderNode>
```
