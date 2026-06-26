---
name: uniai-research
description: Search the web for up-to-date information and return a summary plus a list of result titles, URLs, and snippets. Use this when the user asks to look something up, find current or recent information, research a topic, check the latest news, or verify a fact that may have changed (e.g. "research this", "search the web for ...", "what's the latest on ...", "look this up online").
---

# UniAI Research (Web Search)

Search the web and bring back a summary with cited results. This skill drives the `web_search` tool (provided by the uniai MCP server). It returns synchronously: a short summary followed by a numbered list of titles, URLs, and snippets.

## When to use this skill

Trigger when the answer depends on current or external information, such as:

- "research this / search the web for ... / what's the latest on ... / look this up online"
- verifying a fact that may have changed since your training data

Prefer this over guessing whenever the question turns on recent events, prices, releases, or other data that may have changed.

## How to generate

Use the `web_search` tool (from the uniai MCP server). If `web_search` is not already among your available tools, first call `tool_search` to load it (search e.g. "web search"), then call it. If it still cannot be found after searching, tell the user that web search isn't available in this environment rather than guessing.

Call `web_search` with these arguments:

- `query` (required, string) — the search query or keywords in natural language, **up to 200 characters**.
- `limit` (optional, number) — maximum number of results to return, **1–20**, default `10`.

The tool returns a summary plus the numbered results. If the response is marked as AI-approximated (live search was unavailable), treat the results as potentially inaccurate and say so to the user.

## Writing a good query

1. **Be specific and keyword-focused** — "UniAI codex-app release notes 2026" beats "what's new".
2. **Add time or scope words** when freshness matters — "latest", "2026", "this week".
3. **Split distinct questions** into separate calls rather than cramming them into one query.
4. **Tune `limit`** — a small `limit` (3–5) for a quick fact, a larger one (10–20) for broader research, then synthesize and **cite the URLs** in your answer.

## Constraints

- `query` must be non-empty and at most 200 characters.
- `limit` must be between 1 and 20.
- Results may be AI-approximated when live search is unavailable; flag that uncertainty to the user instead of presenting it as verified.
- This tool returns search results; it does not open or fetch full page contents.
