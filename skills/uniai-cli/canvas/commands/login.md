# `uniai canvas login` / `whoami` — authenticate

Canvas reuses the same credentials as the rest of the `uniai` CLI. Today the **only** login
mechanism is a Personal Access Token (PAT) that starts with `uap_` (browser login is planned but not
shipped). Credentials live in `~/.uniai/config.json`.

> The top-level `uniai auth login --token <pat>` writes the same `~/.uniai/config.json`, so if the
> user already ran that, canvas is already authenticated — just check with `whoami`.

## Credential & endpoint precedence (every canvas verb)

- token: `--token <pat>` → `UNIAI_TOKEN` env → `~/.uniai/config.json` `token`. Missing → friendly
  error: `No UniAI token. Run \`uniai auth login --token <PAT>\`, set UNIAI_TOKEN, or pass --token <PAT>.`
- API base: `--api-base <url>` → `UNIAI_API_BASE` env → `config.apiBase` → default
  `https://www.uniai.ai/api/v1`. For local/dev testing override with `UNIAI_API_BASE`, do not edit source.

## `uniai canvas login`

Usage skeleton: `uniai canvas login --token <uap_…PAT> [--api-base <url>] [--json]`

- Token source: `--token`, else `UNIAI_TOKEN`. None → usage (exit 2).
- Validates the PAT format (`uap_` + 24+ url-safe chars). Bad format → exit 1:
  `invalid PAT format (<reason>). Expected uap_… personal access token.`
- Writes/merges `~/.uniai/config.json` (also stores `apiBase` if `--api-base` given).
- Output: non-json → stderr `saved credentials to ~/.uniai/config.json`; json →
  `{"ok":true,"loggedIn":true}`. exit 0.

How to get a PAT: tell the user to create one at <https://www.uniai.ai> → Personal Center → Security →
Personal Access Tokens → Generate. Offer two ways to apply it and let them choose:

- **(A) you do it** — they paste the token into chat, you run `uniai canvas login --token <pasted>`.
- **(B) they do it** — they run it themselves in their terminal so the token never enters chat
  (prefer this for security-conscious users).

**Security: never echo the token back in your prose.** Report only that login succeeded.

## `uniai canvas whoami`

Usage skeleton: `uniai canvas whoami [--json]`

- Calls `GET /auth/profile`.
- Output: non-json → the user's `email` / `username` / `id` (or `authenticated`); json →
  `{"ok":true,"profile":{…}}`. exit 0. Use it to confirm a login worked before building a canvas.

## Examples

```bash
# case 1: log in with a PAT (you run it after the user pastes the token)
uniai canvas login --token uap_xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# case 2: log in against a non-prod endpoint (dev/test)
UNIAI_API_BASE=http://localhost:3011/api/v1 uniai canvas login --token uap_xxxx

# case 3: confirm who is authenticated
uniai canvas whoami --json
```
