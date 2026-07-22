# `uniai canvas workspace` — spaces that hold canvases

A **workspace** is conceptually a container for canvases; a workspace with no team is your
**personal space**.

**Current limitation:** art canvas projects cannot be assigned to a workspace — the unified art
canvas has no workspace field (that belonged to the retired video-agent canvas). `project create
--workspace` is ignored with a warning, and `project list` always lists all your canvases. You can
still create/list workspaces (below), but they do not contain art projects yet.

## Subcommands

| Subcommand | What it does |
| --- | --- |
| `workspace create --name <name>` | Create a workspace, returns its id |
| `workspace list` | List your workspaces (this is also the default when no subcommand) |

(Authoritative options: `uniai canvas workspace --help`.)

### `uniai canvas workspace create`

Usage skeleton: `uniai canvas workspace create --name <name> [--json]`

- Name from `--name` (or positional `args[1]`). Missing → usage (exit 2):
  `usage: uniai canvas workspace create --name <name>`.
- `POST /canvas/workspaces {name}`.
- Output: non-json → `<id>\t<name>`; json → `{"ok":true,"workspace":{…}}`.

### `uniai canvas workspace list`

Usage skeleton: `uniai canvas workspace list [--json]` (also runs when you pass no subcommand)

- `GET /canvas/workspaces`.
- Output: non-json → one `<id>\t<name>` per line; json → `{"ok":true,"workspaces":[…]}`.

## Examples

```bash
# case 1: list workspaces (or just `uniai canvas workspace`)
uniai canvas workspace list

# case 2: create a workspace and capture its id with --json
uniai canvas workspace create --name "Ad campaign Q3" --json
```
