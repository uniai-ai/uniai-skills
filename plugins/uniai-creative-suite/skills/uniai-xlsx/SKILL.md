---
name: uniai-xlsx
description: Build polished, analyst-grade Microsoft Excel (.xlsx) workbooks — data tables, trackers, financial models, dashboards, reports — with styled headers, frozen panes, real number formats, in-cell data-bar visualization, a summary/dashboard sheet, and a render-and-verify loop. Use when the user asks to create a spreadsheet, Excel file, data table, or workbook (e.g. "make a spreadsheet / Excel workbook / tracker / dashboard").
---

# UniAI Spreadsheets (Excel workbooks)

Produce an editable `.xlsx` that reads like an analyst built it — styled, navigable, with real numbers and visual emphasis — **not** a raw value dump. You are judged on data modeling, formatting craft, visual clarity, and a **rendered** result with no defects.

## Engine & contract (read once)

- **Author with the bundled `exceljs` JavaScript library** (write an ESM `build.mjs`, run with `node`). Do **not** use the `xlsx`/SheetJS package (it writes values only — no styles, number formats, freeze, filters, or data bars, which is exactly what makes a workbook look unprofessional), and do **not** use `openpyxl`/Python (not set up here).
- **Verify visually with the `render_document` tool** — it renders a sheet to PDF + PNG (returned inline) so you can *see* formatting defects. **Do not run `soffice`/LibreOffice (or `scripts/render.sh`) yourself in the shell** — LibreOffice crashes (SIGABRT) inside the command sandbox; the `render_document` tool runs it safely outside the sandbox.
- Set up the library with the shipped helper (run from a writable work dir): `scripts/setup_deps.sh <work-dir> exceljs` (links the lib). To render for QA, call the **`render_document`** tool with the **absolute path** to your `.xlsx`.
- If `setup_deps.sh` can't find the lib, or `render_document` reports LibreOffice unavailable, report a setup blocker; do **not** search the filesystem / your home directory / other projects for a cached `exceljs` (or import one found elsewhere), guess paths, `pip install`, or use system Python.

## North star

A workbook a finance or ops team would actually use: an **Overview / dashboard** sheet that states the takeaways with KPIs and an in-cell ranking; data sheets where **numbers are real numbers** (sortable, formatted), the header row is styled and frozen, columns are filterable, and the important metric column carries a **data bar** so magnitude is visible at a glance. Reject a plain grid of strings.

## Non-negotiable: render → SEE every sheet → iterate

A workbook that opens without error is **not** verified — styling, number formats, and data bars only reveal themselves when rendered. Before delivering you MUST look at **every sheet** and fix every defect (values overflowing/colliding across columns, dark-on-dark text, broken/empty data bars, mis-sized columns, strings where numbers should be).

- The `render_document` tool renders the workbook to PDF and returns one image **per page** of that PDF (rasterized in-process via pdfium; the first 12 pages inline). LibreOffice lays each sheet out across one or more pages, and a wide sheet may split or scale across pages.
- Because workbook→PDF pagination is unpredictable, to see **every sheet cleanly** use the **per-sheet trick**: structure `build.mjs` so one sheet can be emitted alone via an `ONLY` env, emit each single-sheet file, then call `render_document` on each:

  ```bash
  mkdir -p _one
  node build.mjs                          # writes the full workbook
  for s in Overview Shipments Funding; do
    ONLY="$s" node build.mjs              # writes _one/$s.xlsx (single sheet)
  done
  ```
  Then call the **`render_document`** tool once per `_one/<sheet>.xlsx` (absolute path) and inspect each returned image.

Never deliver a workbook whose sheets you have not each seen rendered.

## Workflow

1. **Scope.** What the workbook is for (report / tracker / model / dashboard), the sheets, and the audience. Default to an Overview sheet + one sheet per data domain.
2. **Research & verify data.** If the data is factual/numeric, gather and **verify it first** — a source per figure. **Never invent numbers**; mark unknowns `[verify]`. Keep raw values as numbers, units in the header (`Shipments (units)`), not baked into strings.
3. **Model the sheets.** Columns and types per sheet; which column is the key metric (gets a data bar); what the Overview should summarize (3–4 KPIs + one in-cell ranking).
4. **Gate — confirm before building (for substantive or data-bearing workbooks).** Show the user, in chat: the **sheet list + columns**, the **key data with sources** (or `[verify]`), and what the dashboard will show. Get approval or edits, then build. Skip only for trivial asks; never fabricate data to fill cells.
5. **Build** `build.mjs` with `exceljs`; one styling helper applied to every data sheet; emit per-sheet via `ONLY`. `node build.mjs`.
6. **Render & SEE every sheet** with the `render_document` tool (per-sheet, above); fix defects; re-render.
7. **Deliver** the final `.xlsx`.

## Design & quality bar

- **Real numbers, not strings.** `5168` with `numFmt = "#,##0"`, never `"5168 units"`. Currencies/percent via `numFmt` (`#,##0` / `0.0%` / `"$"#,##0`). Strings can't be sorted, summed, formatted, or data-barred.
- **Styled, frozen header** on every data sheet: solid fill, bold light text, bottom border; `views: [{ state: "frozen", ySplit: 1 }]`; `autoFilter` across the header.
- **Banded rows** (alternating subtle fill), thin/hairline row borders, vertically centered cells with breathing room, deliberate column widths sized to content (short fields narrow, prose wide).
- **In-cell data bars for the key metric** — exceljs has **no native charts**, so a conditional-format `dataBar` is your bar chart. The rule **must** include `cfvo: [{ type: "min" }, { type: "max" }]` or rendering crashes.
- **Overview / dashboard sheet**: a title + one-line takeaway, 3–4 KPI figures (give each value enough column width or **merge across columns** so a wide value like `$1.4B` can't overflow into the next), and a compact ranking with data bars.
- **No collisions**: a value wider than its column overflows into the neighbor — widen the column or merge cells. Watch merged-cell math (`mergeCells(top,left,bottom,right)`).
- **Never invent stats.** Mark unknowns `[verify]` and tell the user.

## Build essentials (`exceljs`)

```js
// build.mjs — run: node build.mjs   (after setup_deps.sh links node_modules)
// full book:  node build.mjs        single sheet:  ONLY=Shipments node build.mjs
import ExcelJS from "exceljs";
const ACCENT = "FF2E6DA4", HEAD_TXT = "FFFFFFFF", BAND = "FFF2F6FB", BORDER = "FFD7E0EA";

// One helper, applied to every data sheet → a coherent system.
function styleTable(ws, numCols) {
  ws.views = [{ state: "frozen", ySplit: 1 }];
  const h = ws.getRow(1); h.height = 26;
  h.eachCell((c, col) => { if (col > numCols) return;
    c.fill = { type: "pattern", pattern: "solid", fgColor: { argb: ACCENT } };
    c.font = { bold: true, color: { argb: HEAD_TXT }, size: 11 };
    c.alignment = { vertical: "middle", wrapText: true };
  });
  for (let r = 2; r <= ws.rowCount; r++) { const row = ws.getRow(r); row.height = 20;
    row.eachCell((c, col) => { if (col > numCols) return;
      c.alignment = { vertical: "middle", wrapText: true };
      c.border = { bottom: { style: "hair", color: { argb: BORDER } } };
      if (r % 2 === 0) c.fill = { type: "pattern", pattern: "solid", fgColor: { argb: BAND } };
    });
  }
  ws.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: numCols } };
}

const wb = new ExcelJS.Workbook();
wb.creator = "UniAI"; wb.created = new Date(0);   // fixed date → deterministic file

const ws = wb.addWorksheet("Shipments");
ws.columns = [{ header: "Company", key: "co", width: 18 }, { header: "Shipments (units)", key: "n", width: 16 }];
[["AgiBot", 5168], ["Unitree", 4200], ["UBTech", 1000]].forEach(([co, n]) => ws.addRow({ co, n }));
ws.getColumn("n").numFmt = "#,##0";               // real number, formatted
styleTable(ws, 2);
ws.addConditionalFormatting({ ref: "B2:B4", rules: [
  { type: "dataBar", cfvo: [{ type: "min" }, { type: "max" }], color: { argb: ACCENT }, gradient: false }, // cfvo REQUIRED
]});

await wb.xlsx.writeFile(process.env.ONLY ? `_one/${process.env.ONLY}.xlsx` : "output.xlsx");
```

- Colors are `AARRGGBB` strings (note the leading alpha `FF`). Conditional-format `dataBar` needs `cfvo`.
- KPI cards / metrics: `mergeCells` across 2+ columns and set the cell font large; size columns so wide values don't overflow.
- `new Date()`/`Date.now()` aren't deterministic — set `wb.created = new Date(0)` (or a passed timestamp) for reproducible output.

## Verification checklist (every delivery)

- Rendered PNG of **every sheet** inspected; no overflow/collision, no dark-on-dark, data bars render.
- Numbers are real numbers with sensible `numFmt`; no `"123 units"`-style strings in metric columns.
- Header styled + frozen + filtered; banded rows; columns sized to content; Overview sheet present and readable.
- No `[verify: …]` placeholders left unless the user agreed.

## Output

- Save under `outputs/<thread>/xlsx/<slug>/` with a descriptive name (e.g. `2026-06-ai-news-data.xlsx`), not `output.xlsx`.
- Deliver **only the final `.xlsx`** (+ a one-line summary). Don't attach `build.mjs`, render PNGs/PDFs, or `_one/` scratch unless asked.
- **Google Sheets target**: build and verify a local `.xlsx` first, then import natively via the Google Drive plugin.

## Constraints / known limits

- **exceljs has no native charts.** Use in-cell **data bars** / color scales for visualization. If a true embedded chart (line/pie) is essential, say so as a limitation — or render the chart in a `.pptx` via `uniai-slides` and reference it — rather than faking it.
- **Per-sheet rendering**: a workbook→PDF lays sheets out unpredictably (a wide sheet may split or scale across pages), so to see each sheet cleanly use the **per-sheet `ONLY` trick** (above) — render each single-sheet file and inspect its page image(s). Page images are rasterized in-process via pdfium (no external poppler needed).
- Relies on the bundled `exceljs` lib + bundled LibreOffice; in packaged builds these must be present (`UNIAI_NODE_LIBS` / `UNIAI_SOFFICE_BIN`). Rendering runs via the `render_document` tool (outside the command sandbox); a direct shell `soffice` call crashes in the sandbox and must not be used.
