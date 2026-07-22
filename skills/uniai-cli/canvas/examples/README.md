# Canvas examples

Copy-pasteable, end-to-end recipes. Each assumes the **common preconditions** below (not repeated per
file):

- Logged in: `uniai canvas whoami` succeeds (see [../commands/login.md](../commands/login.md)).
- A current project is bound in this directory: you ran `uniai canvas project create` or
  `uniai canvas project use <id>` (see [../commands/project.md](../commands/project.md)).
- In a non-interactive shell, standalone `node create` calls redirect `< /dev/null` (see
  [../commands/node.md](../commands/node.md)).

## Index

| Recipe | Covers |
| --- | --- |
| [workflow/create-and-run.md](./workflow/create-and-run.md) | Build a `text → image → video` graph, estimate, confirm, poll, re-query status — the whole safe loop |
| [workflow/diagnose-and-fix.md](./workflow/diagnose-and-fix.md) | Read a `partial`/`failed` run, find the broken node, fix it, re-run |
| [pipes/README.md](./pipes/README.md) | NDJSON pipes: `(a && b) \| c` auto-wiring, fan-in |
