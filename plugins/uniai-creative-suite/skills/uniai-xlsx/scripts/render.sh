#!/usr/bin/env bash
# render.sh — render a .docx/.pptx/.xlsx/.pdf into a PDF plus per-page PNGs for the
#   "render → inspect → edit → re-render" visual verification loop.
#   With pdftoppm (poppler): per-page PNGs (page-1.png…); otherwise fall back to a
#   LibreOffice first-page PNG (single page / quick self-check).
#
# Usage:  bash render.sh <input-file> [out-dir]
set -euo pipefail

IN="${1:?usage: render.sh <input-file> [out-dir]}"
OUTDIR="${2:-$(cd "$(dirname "$IN")" && pwd)/_render}"
BASE="$(basename "${IN%.*}")"

resolve_soffice() {
  if [ -n "${UNIAI_SOFFICE_BIN:-}" ] && [ -x "${UNIAI_SOFFICE_BIN}" ]; then echo "$UNIAI_SOFFICE_BIN"; return; fi
  command -v soffice >/dev/null 2>&1 && { command -v soffice; return; }
  for c in \
    "$(dirname "$0")/../../../../../../../desktop/src-tauri/libreoffice/LibreOffice.app/Contents/MacOS/soffice" \
    "$HOME/Ai/uniai-all/codex-app/desktop/src-tauri/libreoffice/LibreOffice.app/Contents/MacOS/soffice" \
    "/Applications/LibreOffice.app/Contents/MacOS/soffice"; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  return 1
}

mkdir -p "$OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"   # absolute path: a relative outdir turns -env:UserInstallation=file://$PROFILE into an invalid relative URL and soffice hangs
PROFILE="$OUTDIR/.louser"; mkdir -p "$PROFILE"

# 1) → PDF (the PDF is the authority for final visual verification, any page count). If the input is already a PDF, use it as is.
if [ "${IN##*.}" = "pdf" ]; then
  PDF="$IN"
else
  SOFFICE="$(resolve_soffice)" || { echo "ERROR: LibreOffice (soffice) not found; set UNIAI_SOFFICE_BIN." >&2; exit 2; }
  "$SOFFICE" --headless "-env:UserInstallation=file://$PROFILE" --convert-to pdf --outdir "$OUTDIR" "$IN" >/dev/null 2>&1
  PDF="$OUTDIR/$BASE.pdf"
fi

# 2) → per-page PNGs: prefer pdftoppm (poppler), otherwise a LibreOffice first-page PNG.
PDFTOPPM="${UNIAI_POPPLER_BIN:-}"; [ -z "$PDFTOPPM" ] && PDFTOPPM="$(command -v pdftoppm || true)"
if [ -n "$PDFTOPPM" ] && [ -f "$PDF" ]; then
  "$PDFTOPPM" -png -r 110 "$PDF" "$OUTDIR/page" >/dev/null 2>&1 || true
  echo "rendered: $PDF + per-page PNGs ($OUTDIR/page-*.png)"
else
  SOFFICE="${SOFFICE:-$(resolve_soffice || true)}"
  [ -n "$SOFFICE" ] && "$SOFFICE" --headless "-env:UserInstallation=file://$PROFILE" --convert-to png --outdir "$OUTDIR" "$IN" >/dev/null 2>&1 || true
  echo "rendered: $PDF + first-page PNG (per-page PNGs need poppler/pdftoppm; otherwise verify the full document/deck against the PDF)"
fi
ls -1 "$OUTDIR"/*.pdf "$OUTDIR"/*.png "$OUTDIR"/page-*.png 2>/dev/null | sort -u || true
