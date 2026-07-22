# `uniai canvas project` — a canvas

A **project** is one canvas: a DAG of nodes and edges. Almost every other verb (`node`, `connect`,
`group`, `run`) operates on a single "current project", which is bound to the working directory via
`.uniai/project.json`. Bind it once, then omit `--project` everywhere else.

## The current-project binding (`.uniai/project.json`)

- Location: `<cwd>/.uniai/project.json` (per working directory — **not** `~/.uniai`).
- Schema: `{ "projectId": "<id>" }` (only `projectId` is written today).
- `project create` (unless `--no-use`) and `project use` write it. Reading is fault-tolerant — a
  missing/corrupt file is treated as empty.
- Resolution order wherever a project is needed: `--project <id>` flag → `.uniai/project.json`
  `projectId`. Neither present → error:
  `No current project. Run \`uniai canvas project use <id>\` or pass --project <id>.`

## Subcommands

| Subcommand | What it does |
| --- | --- |
| `project create --name <name> [--no-use]` | Create a canvas; binds it as current unless `--no-use` |
| `project use <projectId>` | Bind an existing canvas as current (no network call) |
| `project get [<id>]` | Show a canvas summary (nodes + edges); defaults to current |
| `project list` | List your canvases |

### `uniai canvas project create`

Usage skeleton: `uniai canvas project create --name <name> [--no-use] [--json]`

- Name from `--name` (or positional `args[1]`). Missing → usage (exit 2).
- `--workspace <id>` is **ignored with a stderr warning** — art canvas projects have no workspace
  assignment (that field belonged to the retired video-agent canvas; the backend rejects it).
  Workspaces (see [workspace.md](./workspace.md)) can still be created/listed but do not contain
  art projects.
- `POST /art/projects {name, type:"design"}` (the unified art canvas — `type` is always
  `"design"`). Unless `--no-use`, the new id is written to `.uniai/project.json` (so subsequent
  commands target it automatically).
- Output: non-json → `<id>\t<name>[\t(current)]`; json → `{"ok":true,"project":{…},"bound":<bool>}`.

### `uniai canvas project use`

Usage skeleton: `uniai canvas project use <projectId>` — **no network call**; just writes the binding.

- Id from positional `args[1]` (or `--project`). Output: non-json → stderr
  `current project set to <id> (.uniai/project.json)`; json → `{"ok":true,"projectId":"<id>"}`.

### `uniai canvas project get`

Usage skeleton: `uniai canvas project get [<id>] [--project <id>] [--json]`

- Id from positional `args[1]`, else the current project. `GET /art/projects/<id>`.
- Output: non-json → a header `project <id> "<name>" — <n> nodes, <m> edges` then one
  `  node <id>\t<type>[\t"<label>"][\t<status>]` per node (label/status only when present);
  json → `{"ok":true,"project":{…}}`.
- Use this to inspect the graph you've built (node ids, types, current status) before a run.

### `uniai canvas project list`

Usage skeleton: `uniai canvas project list [--json]`

- `GET /art/projects`. non-json → one `<id>\t<name>` per line; json → `{"ok":true,"data":<raw>}`.

### `uniai canvas project delete`

Usage skeleton: `uniai canvas project delete <projectId> --yes`

- `DELETE /art/projects/:id`. **IRREVERSIBLE** — removes the whole canvas (nodes, edges, media references).
- Without `--yes` it refuses and exits 1. Get the user's explicit confirmation in chat FIRST,
  then re-run with `--yes`. Never pass `--yes` on your own initiative.
- To clear a canvas but keep the project, delete nodes instead (`node delete --prune-edges`).

## Examples

```bash
# case 1: create a canvas and make it current in this directory
uniai canvas project create --name "promo-clip"

# case 2: bind an existing canvas to this directory, then inspect it
uniai canvas project use 7f3c…-uuid
uniai canvas project get

# case 3: create without binding (you'll pass --project explicitly later)
uniai canvas project create --name "scratch" --no-use --json
```
