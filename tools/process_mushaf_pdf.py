#!/usr/bin/env python3
"""Convert a Madani Mushaf PDF into optimised WebP pages.

The authentic page-by-page Mushaf mode needs one image per printed page
(604 pages for the standard Madani Mushaf). Shipping those as WebP keeps the
bundle small enough to embed in the app.

Usage
-----
    # From a local PDF
    python3 tools/process_mushaf_pdf.py --input mushaf.pdf --output assets/mushaf

    # Download a public-domain 604-page Madani Mushaf PDF first
    python3 tools/process_mushaf_pdf.py --url <pdf-url> --output assets/mushaf

    # Render a subset while iterating
    python3 tools/process_mushaf_pdf.py --input mushaf.pdf --pages 1-10

The script writes ``page_001.webp`` … ``page_604.webp`` into the output
directory and prints the total size so the <40 MB target can be checked.
"""

from __future__ import annotations

import argparse
import io
import sys
import urllib.request
from pathlib import Path

try:
    import pymupdf
except ImportError:  # pragma: no cover - guidance for a missing optional dep
    pymupdf = None

try:
    from PIL import Image
except ImportError:  # pragma: no cover - guidance for a missing optional dep
    Image = None

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUTPUT = REPO_ROOT / "assets" / "mushaf"

EXPECTED_PAGES = 604
TARGET_HEIGHT_PX = 1260
WEBP_QUALITY = 82
USER_AGENT = "bayan-quran-mushaf-tool/1.0 (+https://github.com/bayan-islamic/quran)"


def require_dependencies() -> None:
    missing = []
    if pymupdf is None:
        missing.append("pymupdf")
    if Image is None:
        missing.append("Pillow")
    if missing:
        raise SystemExit(
            "missing dependency: " + ", ".join(missing)
            + "\ninstall with: pip install pymupdf Pillow"
        )


def parse_pages(spec: str | None, total: int) -> list[int]:
    """Parse a 1-based page selection such as ``1-10``, ``3`` or ``1,5,9``."""
    if spec is None:
        return list(range(1, total + 1))

    pages: list[int] = []
    for chunk in spec.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        if "-" in chunk:
            start, end = (int(part) for part in chunk.split("-", 1))
            pages.extend(range(start, end + 1))
        else:
            pages.append(int(chunk))

    invalid = [p for p in pages if p < 1 or p > total]
    if invalid:
        raise SystemExit(f"page(s) out of range 1-{total}: {invalid}")
    return sorted(dict.fromkeys(pages))


def download_pdf(url: str, destination: Path) -> Path:
    if destination.exists():
        print(f"using cached pdf {destination}")
        return destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    print(f"downloading {url}")
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=300) as response:  # noqa: S310
        destination.write_bytes(response.read())
    print(f"saved {destination} ({destination.stat().st_size / 1_048_576:.1f} MB)")
    return destination


def render_page(page: "pymupdf.Page") -> "Image.Image":
    """Render one PDF page at the target height, preserving aspect ratio."""
    rect = page.rect
    zoom = TARGET_HEIGHT_PX / rect.height
    matrix = pymupdf.Matrix(zoom, zoom)
    pixmap = page.get_pixmap(matrix=matrix, alpha=False)
    image = Image.open(io.BytesIO(pixmap.tobytes("png")))
    return image.convert("RGB")


def save_webp(image: "Image.Image", destination: Path) -> int:
    image.save(
        destination,
        format="WEBP",
        quality=WEBP_QUALITY,
        method=6,
    )
    return destination.stat().st_size


def convert(pdf_path: Path, output_dir: Path, pages: list[int]) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    document = pymupdf.open(pdf_path)
    try:
        total = document.page_count
        for number in pages:
            if number > total:
                raise SystemExit(
                    f"pdf has only {total} pages but page {number} was requested"
                )
            image = render_page(document[number - 1])
            destination = output_dir / f"page_{number:03d}.webp"
            size = save_webp(image, destination)
            written.append(destination)
            print(
                f"page {number:03d}/{total} -> {destination.name} "
                f"({image.width}x{image.height}, {size / 1024:.0f} KB)"
            )
    finally:
        document.close()
    return written


def report(output_dir: Path, written: list[Path]) -> None:
    total_bytes = sum(path.stat().st_size for path in written)
    total_mb = total_bytes / 1_048_576
    print("-" * 60)
    print(f"pages written : {len(written)}")
    print(f"output dir    : {output_dir}")
    print(f"total size    : {total_mb:.1f} MB")
    if len(written) == EXPECTED_PAGES:
        status = "OK" if total_mb < 40 else "ABOVE the 40 MB target"
        print(f"target < 40 MB: {status}")
    else:
        print(f"note: expected {EXPECTED_PAGES} pages for the full Madani Mushaf")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--input", type=Path, help="path to a local Mushaf PDF")
    source.add_argument("--url", help="public-domain Mushaf PDF URL to download")
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"directory for the WebP pages (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--cache",
        type=Path,
        default=REPO_ROOT / "tools" / "cache" / "mushaf.pdf",
        help="where a --url download is cached",
    )
    parser.add_argument(
        "--pages",
        help="1-based selection to render, e.g. '1-10' or '1,5,9' (default: all)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    require_dependencies()
    args = build_parser().parse_args(argv)

    pdf_path = args.input if args.input else download_pdf(args.url, args.cache)
    if not pdf_path.exists():
        raise SystemExit(f"pdf not found: {pdf_path}")

    with pymupdf.open(pdf_path) as document:
        total = document.page_count
    print(f"{pdf_path.name}: {total} pages")

    pages = parse_pages(args.pages, total)
    written = convert(pdf_path, args.output, pages)
    report(args.output, written)
    return 0


if __name__ == "__main__":
    sys.exit(main())
