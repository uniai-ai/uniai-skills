---
name: uniai-docx
description: Create, edit, and visually verify professional Microsoft Word (.docx) documents — memos, reports, SOPs, proposals, briefs, manuals, forms, and Google Docs-targeted documents — with a strict render-and-verify workflow. Use when the user asks to write, draft, generate, format, or edit a Word/.docx document (e.g. "写一份报告", "做个 Word 文档", "生成一份方案/备忘录/SOP", "make a Word doc / report / proposal / brief", "edit this .docx").
---

# UniAI Word Documents

Produce a polished, correct, **rendered-and-verified** `.docx` that could pass for a strong analyst's or designer's work — not just a functional text dump. You are judged on layout, readability, typographic hierarchy, table craft, and correctness.

## Engine & contract (read once)

- **Author with the bundled `docx` JavaScript library** (write an ESM `build.mjs`, run it with `node`). Do **not** use `python-docx`, `openpyxl`, or shell heredocs — the container's Python document libraries are not installed; the JS `docx` lib is.
- **Verify visually with the `render_document` tool** — it renders your `.docx` to a PDF + page image(s) and returns the images inline, so you can *see* layout defects that text/XML inspection misses. **Do not run `soffice`/LibreOffice (or `scripts/render.sh`) yourself in the shell** — LibreOffice crashes (SIGABRT) inside the command sandbox; the `render_document` tool runs it safely outside the sandbox.
- Set up the library with the shipped helper (run from a writable work dir, not the skill dir):
  - `scripts/setup_deps.sh <work-dir> docx` — links the `docx` library so `import "docx"` resolves.
- To render for QA: call the **`render_document`** tool with the **absolute path** to your `.docx` (it produces the PDF + page images).
- If `setup_deps.sh` cannot find the library, or `render_document` reports LibreOffice is unavailable, report a setup blocker (or deliver with a clear "visual QA not run" note); do not guess paths, search the filesystem / your home directory / other projects for a cached `docx` (or import one found elsewhere), `pip install`, or use system Python.

## Non-negotiable: render → inspect → iterate

**You do not "know" a `.docx` is good until you have rendered it and looked at the page images.** Before delivering any document you MUST:

1. Call the `render_document` tool (pass the absolute path to your `.docx`) to produce a PDF and page image(s).
2. Look at the returned page images. **The tool returns one image per page (rendered in-process via pdfium) — inspect them all.** For a long document only the first 12 page images are returned inline (the full PDF still covers every page); to scrutinize a specific later page beyond that, build a small temporary `build.mjs` with just that section and render it. Do not assume unseen pages are clean.
3. If anything is off — clipped text, overlap, broken table, bad spacing, awkward page break — fix `build.mjs` and **re-render**. Repeat until flawless.

Never deliver an unrendered document. If LibreOffice is unavailable, deliver the `.docx` but state clearly that visual QA could not be run — do not imply it passed the render gate.

## Workflow

1. **Plan the document.** Decide the archetype (memo / report / SOP / proposal / form / manual) and a design system *before* writing: page + margins, type scale, heading ladder, table style, callout/box style, spacing, accent color, header/footer. Map each content unit to the right **form factor** (prose, lead callout, numbered steps, grouped bullets, checklist, note box, definition list, table, form). Use the *lightest* readable structure. For factual or numeric content, gather and **verify the data first** — keep a source per number; **never invent figures**, mark unknowns `[verify]`.
2. **Gate — confirm before writing the full document (for substantive or data-bearing docs).** Show the user, in chat, a short **outline** (sections + what each will contain) and the **key data with sources** (or `[verify]`). Get approval or edits, then build. Skip the gate only for trivial asks ("fix the wording of this paragraph"); never fabricate data to fill a report.
3. **Set up deps** in your work dir (`outputs/<thread>/docx/<slug>/`): `bash <skill>/scripts/setup_deps.sh "$WORKDIR" docx`.
4. **Build** `build.mjs` (bulk-write structure → styles/formatting → tables → headers/footers), then `node build.mjs` to emit the `.docx`.
5. **Render & inspect** with the `render_document` tool; fix the worst defects first; re-render.
6. **Deliver** only the final `.docx` (see Output).

## Design & quality bar

Resolve the design into concrete numbers and apply them — do not rely on Word/library defaults.

- **Page**: US Letter portrait, ~1in margins, unless the user asks otherwise.
- **Type scale**: title ~26–32pt, H1 ~16–18pt, H2 ~13–14pt, body ~11pt, captions ~9–10pt. One professional, readable font system; intentional bold/italic, never decorative.
- **Headings**: real heading styles with a clear ladder — not bold paragraphs faking headings.
- **Lists**: real numbering/bullets — never fake bullets with "•"/"-" text or manual numbers; wrapped lines align under the item text, not the marker.
- **Tables** (invest here — most defects live here):
  - Deliberate column widths sized to content (short fields compact, prose columns wide) — not equal-width-by-default; never full-page-width by reflex.
  - Generous, consistent cell padding; text vertically centered; never pinned to the top-left or hugging borders.
  - Never use fixed row heights that truncate; let rows grow with wrapped content.
  - Headers repeat on multi-page tables; keep clear spacing between a table and surrounding text.
  - Do not use tables to package prose — if cells become mini-paragraphs, switch to prose/bullets/callouts.
- **Spacing**: generous, consistent vertical rhythm between sections; avoid large blank gaps from a table/figure pushed to the next page (scale or split it with repeated headers).
- **Color**: intentional for title/headings/emphasis; restrained for formal documents.
- **Do not** ship visible defects: clipped/overlapping text, broken tables, unreadable glyphs, misplaced headers/footers. Prefer ASCII hyphens over exotic Unicode dashes.

For **edits** to an existing `.docx`: import it, make minimal local changes, preserve the original design system and structure; do not blanket-rewrite. Extend existing patterns (e.g. a new table row inherits the table's styling).

## Build essentials (`docx` library)

```js
// build.mjs — run: node build.mjs   (after setup_deps.sh links node_modules)
import fs from "node:fs/promises";
import {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, BorderStyle, LevelFormat,
} from "docx";

const ACCENT = "1F4E79"; // resolve your palette to hex tokens up front

const doc = new Document({
  styles: { default: { document: { run: { font: "Calibri", size: 22 } } } }, // size is half-points (22 = 11pt)
  numbering: { config: [{ reference: "nums", levels: [
    { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.START },
  ]}]},
  sections: [{
    properties: { page: { margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 } } }, // 1440 twips = 1in
    children: [
      new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun({ text: "Quarterly Operating Review", color: ACCENT })] }),
      new Paragraph({ heading: HeadingLevel.HEADING_1, text: "Summary" }),
      new Paragraph({ children: [new TextRun("One dense, source-backed paragraph beats five thin ones.")] }),
      new Paragraph({ text: "First step", numbering: { reference: "nums", level: 0 } }),
      new Table({
        width: { size: 100, type: WidthType.PERCENTAGE },
        columnWidths: [3000, 6360], // twips; sum ≈ usable width (9360 for Letter/1in margins)
        rows: [
          new TableRow({ tableHeader: true, children: [
            cell("Metric", true), cell("Value", true),
          ]}),
          new TableRow({ children: [ cell("Revenue"), cell("$12.4M") ]}),
        ],
      }),
    ],
  }],
});

function cell(text, header = false) {
  return new TableCell({
    margins: { top: 80, bottom: 80, left: 120, right: 120 }, // twips — breathing room
    children: [new Paragraph({ children: [new TextRun({ text, bold: header })] })],
  });
}

await fs.writeFile("output.docx", await Packer.toBuffer(doc));
console.log("wrote output.docx");
```

- Prefer block construction; resolve numeric tokens (sizes in **half-points**, widths/margins in **twips**: 1in = 1440 twips) once and reuse.
- For images, embed via `ImageRun`. For tracked changes / comments / fields, the `docx` lib covers common cases; if a niche OOXML feature is missing, note the limitation rather than faking it.

## Verification checklist (every delivery)

- Rendered PDF/PNG exists; page count matches expectation.
- Inspected at 100%: no clipping, overlap, broken tables, missing glyphs, or header/footer drift.
- Tables: aligned columns, centered text, consistent padding, no truncation, repeated headers across pages.
- Headings/lists are real styles (not faked); spacing is even; no large empty gaps.
- No tool-citation tokens or `[verify: …]` placeholders left in the final text unless the user asked to keep them.

## Output

- Save the final file under `outputs/<thread>/docx/<slug>/` with a descriptive name (e.g. `q3-operating-review.docx`), not `output.docx`.
- Deliver **only the final `.docx`** — not the `build.mjs`, render PDFs/PNGs, or scratch files, unless the user asks for them. Report the path + a one-line summary.
- **Google Docs target**: build and verify a local `.docx` here first, then import it natively via the Google Drive plugin's document-import action. Do not build directly against Google Docs unless the user explicitly asks.

## Constraints / known limits

- **Per-page page images** are rendered in-process via pdfium (BSD-licensed WASM) — no external `pdftoppm`/poppler needed. The `render_document` tool returns one PNG per page automatically (the first 12 pages inline; the full PDF covers any beyond that).
- Runtime: relies on the bundled `docx` JS lib + bundled LibreOffice. In packaged builds these must be present (`UNIAI_NODE_LIBS` / `UNIAI_SOFFICE_BIN`); if missing, report a setup blocker. Rendering runs via the `render_document` tool (outside the command sandbox); a direct shell `soffice` call crashes in the sandbox and must not be used.
