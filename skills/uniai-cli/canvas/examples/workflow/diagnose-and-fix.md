# Workflow: diagnose a `partial` / `failed` run and fix it

**Covers:** reading a run that didn't fully succeed, locating the broken node, fixing the cause, and
re-running — without blindly retrying.

**Preconditions:** the common ones in [../README.md](../README.md); a project bound and at least one
run attempted.

```bash
# 1) the confirmed run came back partial (some nodes failed, others succeeded)
#    NOTE: a "partial" run is ok:true / exit 0 — don't treat it as a hard failure. Read run.status
#    and per-node nodeStatuses[].status to find what actually broke.
uniai canvas run --confirm --json
# → {"ok":true,"run":{"runId":"…","status":"partial","nodeStatuses":[
#      {"nodeId":"n1","type":"text","status":"completed"},
#      {"nodeId":"n2","type":"image","status":"completed"},
#      {"nodeId":"n3","type":"video","status":"failed","error":"duration 12 exceeds model max"}]}}

# 2) (or re-query a run by id later — read-only, no spend)
uniai canvas run --status <runId> --json

# 3) find the failed node's cause in `error`, then check what the model actually allows
uniai canvas model --node-type video --json   # read config for the legal duration / ratios

# 4) fix the cause. The CLI has no `node update` and no `node delete`, and `run` re-executes the WHOLE
#    graph and re-bills every generatable node (it is NOT incremental — see the cost warning below).
#    So the cleanest fix for a small graph is usually to start a fresh project with corrected params:
uniai canvas project create --name "cabin-promo-fix"
uniai canvas node create --type text --content "a lone cabin under aurora" \
  | uniai canvas node create --type image --model <imageModelId> \
  | uniai canvas node create --type video --model <videoModelId> \
        --prompt "slow push-in, snowfall" --duration 4 --aspect-ratio 16:9

# 5) estimate + confirm again
uniai canvas run
uniai canvas run --confirm
```

Key points:

- A `failed` node does **not** abort the graph — independent branches still run. Nodes downstream of a
  failed one are marked `skipped`. The whole run is `partial` if some nodes completed, `completed` if
  all did, and `failed` only if none completed. `partial`/`completed` → `ok:true` / exit 0; `failed` →
  `ok:false` / exit 1. **Read `run.status` and each `nodeStatuses[].status`/`.error`** — don't rely on
  the top-level `ok` alone.
- Common causes: an out-of-range `--duration`/`--aspect-ratio` for the chosen model, an empty/missing
  prompt, a `video` node whose chosen model is image-to-video only but has no first frame upstream, a
  `video_clip` with no upstream `video`, or `INSUFFICIENT` balance at the estimate step. (`image_editor`
  is the only node type not yet runnable.)
- **Cost warning — `run` is not incremental.** Each `uniai canvas run --confirm` re-executes the entire
  project graph and **re-bills every generatable (image/video/audio) node**, including ones that already
  succeeded — there is no skip-if-done and no single-node run. Failed nodes themselves aren't charged,
  but re-running to fix one re-charges the good ones too.
- There is **no `node delete`** (the `node` verb only does `create`), so a broken node can't be removed
  — it will keep re-running on every run. Prefer keeping graphs small and rebuilding into a fresh
  project over patching a node in place.
- Don't "fix" by repeatedly `--confirm`-ing the same broken graph — change the cause first.
