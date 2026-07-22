#!/usr/bin/env bash
# setup_deps.sh — symlink node_modules into the work dir so build scripts can `import "<lib>"` (ESM ignores NODE_PATH).
# Resolution order: UNIAI_NODE_LIBS (library dir injected by the packaged app) → the dev repo's pnpm store.
#
# Usage:  bash setup_deps.sh <work-dir> <lib>      (lib e.g. docx / pptxgenjs / exceljs)
set -euo pipefail

WORKDIR="${1:?usage: setup_deps.sh <work-dir> <lib>}"
LIB="${2:?library name required, e.g. docx}"
mkdir -p "$WORKDIR"

# Candidates: the packaged app lays libraries out under UNIAI_NODE_LIBS; in dev they live in the repo's .pnpm/<lib>@*/node_modules (the lib plus its deps).
NM=""
if [ -n "${UNIAI_NODE_LIBS:-}" ]; then
  # UNIAI_NODE_LIBS is set (packaged app / dev after fetch-node-libs.sh) = the authoritative library dir; the lib must be there.
  # No fallback to repo scanning — scanning stray node_modules caches when injection breaks is exactly the
  # "hunt the whole disk for libraries" behavior creative-suite is meant to eliminate.
  if [ -d "${UNIAI_NODE_LIBS}/$LIB" ]; then
    NM="$UNIAI_NODE_LIBS"
  else
    echo "ERROR: UNIAI_NODE_LIBS is set ($UNIAI_NODE_LIBS) but '$LIB' is not in it; refusing to fall back to a disk-wide scan. Re-package or re-run scripts/fetch-node-libs.sh." >&2
    exit 2
  fi
else
  # UNIAI_NODE_LIBS not set (dev without fetch) → fall back to the repo pnpm store.
  for root in "$HOME/Ai/uniai-all" "$(cd "$(dirname "$0")/../../../../../../../.." 2>/dev/null && pwd)"; do
    cand="$(ls -d "$root"/node_modules/.pnpm/"$LIB"@*/node_modules 2>/dev/null | head -1)"
    [ -n "$cand" ] && { NM="$cand"; break; }
  done
fi

[ -z "$NM" ] && { echo "ERROR: JS library '$LIB' not found. Point UNIAI_NODE_LIBS at a library dir containing $LIB, or run inside the dev repo." >&2; exit 2; }

ln -sfn "$NM" "$WORKDIR/node_modules"
echo "linked: $WORKDIR/node_modules -> $NM"
[ -d "$WORKDIR/node_modules/$LIB" ] && echo "ok: import \"$LIB\" resolves" || { echo "WARN: $WORKDIR/node_modules/$LIB does not exist" >&2; exit 3; }
