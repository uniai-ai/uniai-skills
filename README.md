# UniAI marketplace & CLI skill

The remote source for UniAI's over-the-air content: the UniAI App plugin marketplace and the
`@uniai/cli` agent skill both point here. Updating content here delivers it to users without an app
reinstall or package update.

> Generated content — do not edit files here by hand; they are replaced on each publish.

## Layout

```
.agents/plugins/marketplace.json   # plugin marketplace manifest (consumed by UniAI App)
plugins/<name>/...                 # plugins (skills + MCP descriptors)
skills/uniai-cli/SKILL.md          # the CLI agent skill (consumed by `uniai skills add`)
CODEOWNERS                         # supply-chain review gate
```

## How it's consumed

- **UniAI App** registers this repo as a git-based plugin marketplace, pinned to the `release` tag.
- **@uniai/cli**: `uniai skills add uniai-ai/uniai-skills --ref release -g` clones and installs the
  `skills/uniai-cli` skill.

## Publishing

Pushing to `main` is a draft. To publish, move the `release` tag — both consumers follow it:

```bash
git tag -f release HEAD && git push -f origin release
```
