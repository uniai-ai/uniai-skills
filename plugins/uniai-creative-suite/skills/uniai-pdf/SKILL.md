---
name: uniai-pdf
description: Create polished, print-ready PDF documents (reports, one-pagers, briefs, proposals, manuals) and read/extract text from existing PDFs, with a strict render-and-verify workflow. Use when the user wants a final PDF deliverable (not an editable Word file), or wants to read/summarize/extract content from a PDF (e.g. "做一份 PDF 报告", "导出成 PDF", "生成 PDF 单页", "make a PDF report / one-pager", "read / extract / summarize this PDF").
---

# UniAI PDF Documents

Produce a clean, professional **PDF** deliverable, or read/extract from an existing PDF. You are judged on layout quality, typographic hierarchy, table craft, and a **rendered** result with no defects.

## When to use this vs uniai-docx
- **uniai-pdf**: the user wants a final **PDF** (print/share, not meant to be edited), or wants to **read/extract** an existing PDF.
- **uniai-docx**: the user wants an **editable Word `.docx`**.
- The two share the same authoring engine; PDF is produced by exporting the authored document.

## Engine & contract (read once)

- **Author rich content with the bundled `docx` JavaScript library** (an ESM `build.mjs`, run with `node`) — exactly like the `uniai-docx` skill (same design/table discipline) — then **export to PDF with the `render_document` tool**. Do **not** use `reportlab`/Python; it isn't set up here. **Do not run `soffice`/LibreOffice (or `scripts/render.sh`) yourself in the shell** — LibreOffice crashes (SIGABRT) inside the command sandbox; the `render_document` tool runs it safely outside the sandbox.
- The PDF is produced by the **`render_document`** tool: call it with the absolute path to your `.docx` — it writes `<name>.pdf` (the deliverable) to `<input-dir>/_render/` plus a page `.png` for QA, and returns the page image(s) inline plus the PDF path.
- Set up the library with the shipped helper (run from a writable work dir): `scripts/setup_deps.sh <work-dir> docx`.
- **Reading/extracting** an existing PDF: use the bundled `pdfjs-dist` (text + page structure). For layout-sensitive review, render the PDF pages with `render_document` and look at them.
- If `setup_deps.sh` can't find the lib, or `render_document` reports LibreOffice unavailable, report a setup blocker; don't guess paths, search the filesystem / your home directory / other projects for a cached lib (or import one found elsewhere), or `pip install`.

## Non-negotiable: render → inspect → iterate

Before delivering, render and **look at the pages**, then fix any clipped/overlapping text, broken table, bad spacing, or awkward page break and re-render. Never deliver an unrendered PDF.

- **`render_document` returns one image per page (rendered in-process via pdfium) — inspect them all.** For a long document only the first 12 page images are returned inline (the full PDF still covers every page); to scrutinize a later page beyond that, render a temporary `build.mjs` with just that section. Don't assume unseen pages are clean.
- **Content check (no poppler needed):** read your own output PDF back with `pdfjs-dist` and scan the per-page text — confirms every section is present, in order, with no leftover `[verify]`/placeholder tokens. This catches content defects even when you can't see all the pixels.

## Workflow (create)

1. **Plan**: archetype (report / one-pager / brief / proposal / manual) + a design system (page, margins, type scale, heading ladder, table style, spacing, accent color, header/footer). Map each content unit to the lightest readable form factor (prose / lead callout / steps / bullets / checklist / note box / table). For factual/numeric content, gather and **verify the data first** — a source per number; **never invent figures**, mark unknowns `[verify]`.
2. **Gate — confirm before building (for substantive or data-bearing PDFs).** Show the user a short outline + the key data with sources (or `[verify]`); get approval or edits, then build. Skip only for trivial asks; never fabricate data to fill the document.
3. **Set up deps**: `bash <skill>/scripts/setup_deps.sh "$WORKDIR" docx`.
4. **Build** `build.mjs` with the `docx` library (see `uniai-docx` SKILL for the API + quality bar: real heading styles, real numbering — no fake bullets, deliberate table column widths with padding and no clipping, even spacing).
5. **Export + render**: call the `render_document` tool with the absolute path to `"$WORKDIR/output.docx"` → produces `output.pdf` (deliverable, under `<input-dir>/_render/`) + page PNG(s) (QA, returned inline).
6. **Inspect** the returned page images (one per page) plus the `pdfjs-dist` text read-back; fix defects; re-build/re-render. Deliver the PDF.

## Workflow (read / extract)

- Load the PDF with `pdfjs-dist` and pull text per page; keep a compact source note (file, page, the exact figure) — do not paste huge excerpts. For layout/figure questions, render pages and inspect the images.

## Quality bar (same as uniai-docx, PDF output)

- US Letter portrait, ~1in margins (unless asked); professional readable type scale; intentional color for title/headings/emphasis.
- Real heading styles + real numbered/bulleted lists (never fake bullets). Tables: content-sized column widths, generous consistent padding, vertically centered text, no truncation, repeated headers on multi-page tables, never tables-as-prose.
- Even vertical rhythm; avoid large blank gaps from a table/figure pushed to the next page (scale or split with repeated headers). No clipped/overlapping/unreadable content. ASCII hyphens over exotic Unicode dashes.

## Verification checklist (every delivery)

- `output.pdf` exists, non-empty, expected page count.
- Inspected at 100%: no clipping/overlap, no broken tables, no missing glyphs, headers/footers correct.
- Tables aligned, padded, untruncated; headings/lists are real styles; spacing even; no leftover `[verify: …]` placeholders unless agreed.

## Output

- Save the final PDF under `outputs/<thread>/pdf/<slug>/` with a descriptive name (e.g. `q3-operating-review.pdf`), not `output.pdf`.
- Deliver **only the final `.pdf`** (+ a one-line summary). Don't attach `build.mjs`, the intermediate `.docx`, or PNGs unless asked.

## Constraints / known limits

- **Authoring-then-export is the supported create path.** PDF-native programmatic work — precise coordinate layout, fillable AcroForms, merging/splitting/stamping/redacting an existing PDF — needs `pdf-lib`, which is **not currently bundled**; if the user needs it, report it as a not-yet-available capability (bundle `pdf-lib` to enable) rather than improvising.
- **Per-page raster QA is built in** — `render_document` rasterizes every page in-process via pdfium (BSD-licensed WASM; no external poppler needed), returning the first 12 page images inline. For a longer PDF, combine the page images with the `pdfjs-dist` text read-back (above).
- Relies on the bundled `docx` lib, `pdfjs-dist`, and bundled LibreOffice; packaged builds must ship these (`UNIAI_NODE_LIBS` / `UNIAI_SOFFICE_BIN`). Rendering runs via the `render_document` tool (outside the command sandbox); a direct shell `soffice` call crashes in the sandbox and must not be used.
