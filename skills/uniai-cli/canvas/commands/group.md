# `uniai canvas group` — list nodes by group

> **Degraded on the unified art canvas (current backend).** Art canvas elements have no `groupKey`
> field, so grouping is **not supported today**: `group list` puts every node under `(ungrouped)`,
> and `--group-key` on `node create` / `node update` is accepted but **ignored** (not persisted).
> Organize related nodes with naming conventions instead (`--name "scene-1/shot-A"`), which shows up
> in `project get` / `node list`.

Usage skeleton: `uniai canvas group list [--project <id>] [--json]`

- Only `list` is supported (and it's the default when no subcommand). Anything else → usage (exit 2):
  `usage: uniai canvas group list [--project <id>]`.
- `GET /art/projects/<projectId>`, then lists all nodes under the single `(ungrouped)` bucket
  (see the degradation note above).
- Output: non-json →
  ```
  (ungrouped):
    <nodeId>\t<type>\t<status>
  ```
  json → `{"ok":true,"groups":{"(ungrouped)":[{"nodeId":…,"type":…,"status":…}]}}`.

## Examples

```bash
# see the current canvas's nodes (all under "(ungrouped)" today)
uniai canvas group list

# organize by naming convention instead of groups
# (< /dev/null avoids any stdin wait when not piping an upstream — see node.md)
uniai canvas node create --type image --prompt "scene 1 shot A" --name "scene-1/shot-A" < /dev/null
uniai canvas node create --type image --prompt "scene 1 shot B" --name "scene-1/shot-B" < /dev/null
```
