#!/usr/bin/env bash
# setup_deps.sh — create a node_modules symlink in the work dir so build scripts can `import "<lib>"` (ESM ignores NODE_PATH).
# Resolution order: UNIAI_NODE_LIBS (lib dir injected in packaged builds) -> dev repo pnpm store.
#
# Usage:  bash setup_deps.sh <work-dir> <lib>      (lib e.g. docx / pptxgenjs / exceljs)
set -euo pipefail

WORKDIR="${1:?Usage: setup_deps.sh <work-dir> <lib>}"
LIB="${2:?Library name required, e.g. docx}"
mkdir -p "$WORKDIR"

# Candidates: packaged builds lay the libs under UNIAI_NODE_LIBS; dev uses the repo .pnpm/<lib>@*/node_modules (which holds the lib + its deps).
NM=""
if [ -n "${UNIAI_NODE_LIBS:-}" ]; then
  # UNIAI_NODE_LIBS is injected (packaged build / dev that ran fetch-node-libs.sh) = authoritative lib dir; the lib must be here, no falling back
  # to a repo scan — avoids mis-scanning other cached node_modules elsewhere when injection breaks (exactly the "search the whole disk for libs" behavior creative-suite aims to eliminate).
  if [ -d "${UNIAI_NODE_LIBS}/$LIB" ]; then
    NM="$UNIAI_NODE_LIBS"
  else
    echo "ERROR: UNIAI_NODE_LIBS is set ($UNIAI_NODE_LIBS) but does not contain '$LIB'; refusing to fall back to a full-disk scan. Re-package or re-run scripts/fetch-node-libs.sh." >&2
    exit 2
  fi
else
  # UNIAI_NODE_LIBS not injected (dev did not run fetch) -> fall back to the repo pnpm store.
  for root in "$HOME/Ai/uniai-all" "$(cd "$(dirname "$0")/../../../../../../../.." 2>/dev/null && pwd)"; do
    cand="$(ls -d "$root"/node_modules/.pnpm/"$LIB"@*/node_modules 2>/dev/null | head -1)"
    [ -n "$cand" ] && { NM="$cand"; break; }
  done
fi

[ -z "$NM" ] && { echo "ERROR: cannot find JS library '$LIB'. Set UNIAI_NODE_LIBS to a lib dir that contains $LIB, or run inside the dev repo." >&2; exit 2; }

ln -sfn "$NM" "$WORKDIR/node_modules"
echo "linked: $WORKDIR/node_modules -> $NM"
[ -d "$WORKDIR/node_modules/$LIB" ] && echo "ok: import \"$LIB\" resolves" || { echo "WARN: $WORKDIR/node_modules/$LIB does not exist" >&2; exit 3; }
