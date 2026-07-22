# Workflow: build a `text → image → video` graph and run it safely

**Covers:** the end-to-end happy path — create a canvas, build a 3-node chain, estimate the cost, get
the user's OK, confirm-run, and re-query if it's still processing.

**Preconditions:** the common ones in [../README.md](../README.md) (logged in). This recipe creates its
own project, so you don't need one bound yet.

```bash
# 1) create the canvas (binds it as current in this directory)
uniai canvas project create --name "cabin-promo"

# 2) pick models (ids come from the catalog — don't hard-code them)
uniai canvas model --node-type image
uniai canvas model --node-type video

# 3) build the chain by piping: text → image → video (edges auto-wired)
uniai canvas node create --type text \
    --content "a lone cabin under the aurora, cinematic, wide establishing shot" \
  | uniai canvas node create --type image --model <imageModelId> --width 1280 --height 720 \
  | uniai canvas node create --type video --model <videoModelId> \
        --prompt "slow cinematic push-in, gentle snowfall, 4 seconds" \
        --duration 4 --aspect-ratio 16:9

# 4) inspect the graph you built
uniai canvas project get

# 5) ESTIMATE first — this spends nothing; show the number to the user
uniai canvas run
# → "estimate: 520 credits (2 generatable); balance 10000, sufficient. re-run with --confirm…"
#    (only image/video/audio nodes count as "generatable" and cost credits; the text source node
#     completes for free, so a 3-node text→image→video graph shows 2 generatable.)

# 6) only after the user approves the estimate, confirm-run (blocks + polls to a terminal state)
uniai canvas run --confirm

# 7) if step 6 reported "still processing (poll budget reached)", re-query by id (no new spend)
uniai canvas run --status <runId>
```

Key points:

- The pipe in step 3 wires `text → image → video` automatically — each `node create` emits its
  `nodeId` on stdout, the next one reads it and connects the edge (see
  [../pipes/README.md](../pipes/README.md)).
- **Never skip step 5.** `run` with no flag is the estimate; `--confirm` is the spend. Show the
  estimate and let the user decide.
- In step 7, use `--status`, never another `--confirm` — re-confirming starts a *second* run.
- The run snapshot (`run` / `run --status`) only reports per-node **status/error**, not asset URLs.
  Final asset URLs live in each node's `data` — read them with `uniai canvas project get --json`.
