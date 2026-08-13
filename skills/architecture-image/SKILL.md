---
name: architecture-image
description: Create crisp architecture, integration, workflow, and system diagrams as editable SVG plus rendered PNG assets. Use when the user asks for an architecture image, architecture diagram, integration diagram, technical flow image, slide-ready system visual, or wants an existing architecture diagram recreated or updated with readable labels. Prefer this over raster AI image generation when exact text, boxes, lanes, arrows, or client-facing technical accuracy matters.
---

# Architecture Image

Use deterministic SVG for architecture visuals so labels stay readable and diagrams remain editable. Render SVG to PNG for decks, docs, and image previews.

## Workflow

1. Inspect any existing diagram first.
   - Extract embedded images from DOCX/PPTX/PDF when needed.
   - Use visual inspection to preserve useful structure, lanes, colors, and relative placement.

2. Clarify architecture facts before drawing.
   - Identify sources, data layer, orchestration, AI/model layer, review experience, sinks, and fallback paths.
   - Mark uncertain facts as validation notes in the diagram or omit them.
   - Do not invent vendor products, APIs, protocols, or data flows.

3. Create an SVG source file in the project.
   - Use lanes for high-level domains such as Source, Data Layer, AI Layer, Experience, Sink.
   - Use boxes for systems and components.
   - Use solid arrows for active data/API flows.
   - Use dashed arrows for existing/background flows.
   - Keep text short and concrete. Architecture diagrams are for scanning, not paragraphs.

4. Render SVG to PNG.
   - Preferred on this machine (crisp text via Node + resvg, system fonts):
     ```bash
     node ~/.claude/skills/architecture-image/scripts/render_svg.mjs diagram.svg diagram.png
     ```
   - Fallback (Python; validates XML, uses `rsvg-convert` if present, else ImageMagick `magick`):
     ```bash
     python ~/.claude/skills/architecture-image/scripts/render_svg.py diagram.svg diagram.png
     ```
   - Both accept an optional `--width N` to upscale. ImageMagick is installed; `rsvg-convert` is not.

5. Validate visually.
   - Open or inspect the PNG.
   - Fix label collisions, clipped text, tiny fonts, crossing arrows, and ambiguous flow direction.
   - Re-render after every SVG edit.

6. Persist both artifacts.
   - Keep the SVG source next to the PNG.
   - Use descriptive names such as `mro-poc-architecture-dremio-ariba-api.svg` and `.png`.
   - Never leave the final asset only in a temp folder.

## Style Defaults

- Canvas: `1200x780` or `1300x780` for slide/doc diagrams.
- Background: light gray `#f6f7f9`.
- Font: Arial or Segoe UI.
- Existing systems: blue.
- Data layer: dark blue.
- Compute/orchestration: green.
- AI/model layer: purple.
- Human review/control: white with blue or orange border.
- API/action path: orange.
- Regular data path: gray or blue.
- Use rounded rectangles with small radii. Avoid decorative gradients.

## SVG Checklist

- Include a `<style>` block for reusable classes.
- Define arrow markers in `<defs>`.
- Use explicit `width`, `height`, and `viewBox`.
- Use separate `<text>` lines instead of relying on text wrapping.
- Keep labels inside boxes and use enough padding.
- Keep legend compact and away from content.
- Ensure text does not overlap arrows or boxes.

## When Replacing Images in DOCX/PPTX

- Replace the embedded image file non-destructively where possible.
- Preserve the document structure and placement.
- Validate the package after replacement:
  ```bash
  unzip -t file.docx
  ```
- For DOCX, run a LibreOffice conversion smoke test when available:
  ```bash
  soffice --headless --convert-to pdf --outdir /tmp/check file.docx
  ```

## Output Requirements

Report:
- SVG path.
- PNG path.
- Any assumptions represented in the diagram.
- Validation performed.

