# UniAI marketplace & CLI skill — OTA content source

This public repo is the **single remote source of truth** for UniAI's over-the-air (OTA) content:
the codex-app plugin marketplace **and** the `@uniai/cli` agent skill both point here. Editing content
here delivers it to users **without** rebuilding the desktop app or republishing the npm package.

> Content only. No product source code lives here.

## Layout

```
.agents/plugins/marketplace.json   # codex marketplace manifest (consumed by codex-app)
plugins/<name>/...                 # codex plugins (skills + MCP descriptors)
skills/uniai-cli/SKILL.md          # the CLI agent skill (consumed by `uniai skills add`)
CODEOWNERS                         # supply-chain review gate
```

## How it's consumed

- **codex-app**: BFF registers this repo as a git marketplace (`codex plugin marketplace add`,
  pinned to the `release` tag). The plugin page's **refresh** button runs `marketplace upgrade`,
  which fast-forwards the snapshot to the moved `release` tag and refreshes installed plugin content.
- **@uniai/cli**: `uniai skills add uniai/uniai-skills --ref release -g` clones and installs the
  `skills/uniai-cli` skill. Re-running picks up updates.

## Publishing = moving the `release` tag (the publish gate)

Pushing to `main` is a **draft** — users don't see it yet. To **publish**, move the `release` tag:

```bash
git tag -f release <commit>     # usually: git tag -f release HEAD
git push -f origin release
```

Both consumers follow the `release` tag, so moving it delivers the change. This extra step is the
safety gate: review on `main`, publish deliberately.

## Supply chain (important)

Skills/plugins run with **full agent permissions** — a malicious edit changes every user's agent
behavior. Protect this repo: branch protection on `main` (PR-only), restricted collaborators, and
`CODEOWNERS` review. Only move the `release` tag from reviewed commits.

## Known limitations

- **Rate limit**: anonymous `git clone`/`ls-remote` is limited to ~60/hr per IP. Fine for individual
  users; a large fleet behind one shared egress IP may hit it — mitigate later with a token or mirror.
- **Self-hosting**: to move off GitHub, point the clients at any https/ssh git host (set
  `CODEX_UNIAI_MARKETPLACE_REMOTE` for codex-app; pass the URL to `uniai skills add`). No BFF code
  change needed — the engine accepts any git host.
