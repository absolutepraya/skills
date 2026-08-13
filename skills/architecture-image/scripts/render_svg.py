#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate an SVG file and render it to PNG using rsvg-convert or ImageMagick."
    )
    parser.add_argument("svg", type=Path, help="Input SVG path")
    parser.add_argument("png", type=Path, help="Output PNG path")
    parser.add_argument("--width", type=int, help="Optional output width in pixels")
    parser.add_argument("--height", type=int, help="Optional output height in pixels")
    return parser.parse_args()


def validate_svg(path: Path) -> None:
    if not path.exists():
        raise SystemExit(f"SVG not found: {path}")
    try:
        ET.parse(path)
    except ET.ParseError as exc:
        raise SystemExit(f"Invalid SVG XML: {exc}") from exc


def render_with_rsvg(svg: Path, png: Path, width: int | None, height: int | None) -> None:
    cmd = ["rsvg-convert"]
    if width:
        cmd += ["-w", str(width)]
    if height:
        cmd += ["-h", str(height)]
    cmd += [str(svg), "-o", str(png)]
    subprocess.run(cmd, check=True)


def render_with_magick(svg: Path, png: Path, width: int | None, height: int | None) -> None:
    magick = shutil.which("magick") or shutil.which("convert")
    if not magick:
        raise SystemExit("No renderer found. Install librsvg (`rsvg-convert`) or ImageMagick (`magick`).")
    cmd = [magick]
    if width and height:
        cmd += ["-size", f"{width}x{height}"]
    cmd += [str(svg), str(png)]
    subprocess.run(cmd, check=True)


def main() -> int:
    args = parse_args()
    validate_svg(args.svg)
    args.png.parent.mkdir(parents=True, exist_ok=True)

    if shutil.which("rsvg-convert"):
        render_with_rsvg(args.svg, args.png, args.width, args.height)
    else:
        render_with_magick(args.svg, args.png, args.width, args.height)

    if not args.png.exists() or args.png.stat().st_size == 0:
        raise SystemExit(f"Render failed or empty output: {args.png}")

    print(f"Rendered {args.svg} -> {args.png}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
