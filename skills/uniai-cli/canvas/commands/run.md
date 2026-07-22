# `uniai canvas run` — execute the graph (estimate → confirm → poll)

`run` executes the **whole** current canvas in dependency order: it topologically sorts the nodes,
generates each one, and flows outputs along the edges. This is the one command that spends credits, so
it is built around a **confirm gate**. There is no per-node run — `run` always runs the graph.

Usage forms:
- `uniai canvas run [--confirm] [--project <id>] [--json]` — estimate, then execute when confirmed.
- `uniai canvas run --status <runId> [--project <id>] [--json]` — query an existing run, spend nothing.

---

## Interaction 1 — the confirm gate (estimate first, `--confirm` to spend)

Running with **no** confirm flag only estimates; nothing is generated and nothing is charged:

```
$ uniai canvas run
estimate: 520 credits (3 generatable); balance 10000, sufficient.
re-run with --confirm to execute.
```

- non-json fields (stderr): the credit **estimate**, how many nodes are **generatable** (and how many
  are **unsupported**, if any), the account **balance**, and whether it is **sufficient**.
- json (`--json`) → `{"ok":true,"needsConfirmation":…,"estimate":…,"generatableNodeCount":…,`
  `"unsupportedNodeCount":…,"balance":…,"sufficient":…}`. exit 0.

**Always show the estimate to the user and let them decide.** Only after they approve, re-run with the
confirm flag (`--confirm`, or its aliases `--yes` / `--confirmed`):

```
$ uniai canvas run --confirm
```

`--confirm` means "the user agreed to spend ~N credits". **This is the only spend gate for canvas** —
there is no unattended/auto-approve environment variable that bypasses it. If `sufficient` was
`INSUFFICIENT`, tell the user to top up before confirming.

Once confirmed, the CLI starts the run and **streams live progress to stderr until the run
finishes** (server pushes per-node events over SSE — no polling, no re-checking):

```
run <runId> started; following progress…
progress: 2/9 nodes done
▶ image shot-1 generating…
✓ [3/9] image shot-1
… still running (3/9 done, 45s elapsed)   ← heartbeat every ~15s
✗ [8/9] video_clip final_cut — <error>
run finished: partial
```

**Keep the command running and keep reading its output until the process exits — it is ONE
command for the WHOLE run.** Do not kill it, do not fire `--status` in parallel, do not end
your turn telling the user to "check progress later". Video graphs take minutes: read with a
long yield (30–60s per read), not a tight 5s loop. stdout stays clean: the final JSON result
is the only thing printed there (`--json` contract unchanged).

If the progress stream is unavailable (older server) the CLI silently falls back to the legacy
3s polling with a ~270s budget. Terminal rendering:

```
run <runId> completed
  <nodeId>\t<type>\t<status>
  <nodeId>\t<type>\t<status>\t<error?>
```

- `completed` or `partial` → exit 0; `failed` (the whole graph failed) → exit 1.
- json → `{"ok":<status!=="failed">,"run":{"runId":…,"status":…,"nodeStatuses":[{nodeId,type,status,error},…]}}`.

---

## Interaction 2 — diagnose & repair

Errors are surfaced, never silently swallowed:

- A bad command / auth / network failure → `{"ok":false,"error":"<msg>"}` (json) or a humanized
  stderr message, exit 1.
- A run can finish **`partial`**: some nodes succeeded, some `failed`. **A failed node does not abort
  the rest of the graph** — independent branches still run. Read `nodeStatuses`, find the entries whose
  `status` is `failed`, and look at their `error`.
- To fix: address the cause (e.g. wrong/empty params, an unsupported node type, insufficient balance),
  rebuild or adjust the offending node, then run again. Don't paper over a failure by blindly retrying
  the same graph.

Billing note: each node bills itself as it generates; failed nodes are not charged, and the confirm
estimate is an estimate, not the exact charge. Re-running only regenerates what you run again.

---

## Interaction 3 — check status without resubmitting

With the live progress stream this should be rare (the command follows the run to the end).
It still applies when the CLI process was killed mid-run, or the legacy polling fallback
exceeds its budget — the run is **not** lost, it continues server-side:

```
run <runId> still processing (poll budget reached). Re-query: uniai canvas run --status <runId>
```
(json → `{"ok":true,"stillRunning":true,"runId":"<id>","run":{…}}`, exit 0.)

To check on it, use `--status` — a **read-only** query that spends nothing and never re-submits:

```
$ uniai canvas run --status <runId>
run <runId> completed
  <nodeId>\t<type>\t<status>
```
- `GET /art/projects/<id>/runs/<runId>`. `failed` → exit 1, otherwise exit 0. json →
  `{"ok":<!failed>,"run":{…}}`.

> **Never re-run `uniai canvas run --confirm` to "check" a run that's still going** — that starts a
> *second* run and can regenerate/charge again. Poll with `--status <runId>` instead.

## Examples

```bash
# the full safe loop: estimate → (user approves) → confirm → (if it times out) re-query by status
uniai canvas run                      # show this estimate to the user
uniai canvas run --confirm            # only after they approve
uniai canvas run --status <runId>     # if it was still processing, re-query (no new spend)
```
