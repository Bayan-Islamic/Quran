#!/usr/bin/env python3
"""Convert a Madani Mushaf PDF into optimised WebP pages.

Mushaf mode needs one image per printed page (604 pages for the standard
Madani Mushaf). Two editions ship side by side:

``standard``
    طبعة مجمع الملك فهد بالمدينة المنورة — the plain Uthmani Madani Mushaf.
``tajweed``
    مصحف التجويد الملون (دار المعرفة) — the same page layout with the
    colour-coded Tajweed palette.

Both editions are aligned page-for-page, so ``page_001.webp`` of each edition
shows the same Qur'anic page. That lets the app swap editions without losing
the reader's place.

Each edition has a tuned preset that keeps the whole 604-page set under the
35 MB budget while staying crisp:

===========  ===========  ======  =======  ==========
edition      first page   height  colours  encoder
===========  ===========  ======  =======  ==========
standard     4            1260    4        palette
tajweed      1            1260    5        palette
===========  ===========  ======  =======  ==========

``first page`` is the PDF page that holds Qur'an page 1: the standard scan
opens with three cover leaves, the Tajweed scan starts straight at Al-Fatihah.

The ``palette`` encoder flattens the scanner's paper grain to pure white and
then quantises the remaining flat colours, which is what makes the lossless
WebP pages small. Pass ``--encoder lossy`` for a higher-fidelity (larger)
build, or ``--colors``/``--height`` to override a preset.

Usage
-----
    # Both editions from local PDFs
    python3 tools/process_mushaf_pdf.py --edition standard \\
        --input tools/cache/standard.pdf --output assets/mushaf/standard
    python3 tools/process_mushaf_pdf.py --edition tajweed \\
        --input tools/cache/tajweed.pdf --output assets/mushaf/tajweed

    # Download the public-domain PDF first
    python3 tools/process_mushaf_pdf.py --edition tajweed --url <pdf-url>

    # Render a subset while iterating
    python3 tools/process_mushaf_pdf.py --edition standard \\
        --input tools/cache/standard.pdf --pages 1-10

The script writes ``page_001.webp`` … ``page_604.webp`` into the output
directory and prints the total size so the < 35 MB target can be checked.
"""

from __future__ import annotations

import argparse
import io
import sys
import urllib.request
from dataclasses import dataclass
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
ASSETS_ROOT = REPO_ROOT / "assets" / "mushaf"

EXPECTED_PAGES = 604
TARGET_TOTAL_MB = 35.0
USER_AGENT = "bayan-quran-mushaf-tool/1.0 (+https://github.com/bayan-islamic/quran)"


@dataclass(frozen=True)
class EditionPreset:
    """Tuned conversion settings for one Mushaf edition."""

    name: str
    first_page: int
    height: int
    colors: int
    flatten_threshold: int
    cache_name: str

    @property
    def default_output(self) -> Path:
        return ASSETS_ROOT / self.name


PRESETS: dict[str, EditionPreset] = {
    "standard": EditionPreset(
        name="standard",
        first_page=4,
        height=1260,
        colors=4,
        flatten_threshold=185,
        cache_name="standard.pdf",
    ),
    "tajweed": EditionPreset(
        name="tajweed",
        first_page=1,
        height=1260,
        colors=5,
        flatten_threshold=185,
        cache_name="tajweed.pdf",
    ),
}


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
    with urllib.request.urlopen(request, timeout=600) as response:  # noqa: S310
        destination.write_bytes(response.read())
    print(f"saved {destination} ({destination.stat().st_size / 1_048_576:.1f} MB)")
    return destination


def render_page(page: "pymupdf.Page", height: int) -> "Image.Image":
    """Render one PDF page at the target height, preserving aspect ratio."""
    rect = page.rect
    zoom = height / rect.height
    matrix = pymupdf.Matrix(zoom, zoom)
    pixmap = page.get_pixmap(matrix=matrix, alpha=False)
    image = Image.open(io.BytesIO(pixmap.tobytes("png")))
    return image.convert("RGB")


def flatten_paper(image: "Image.Image", threshold: int) -> "Image.Image":
    """Snap bright, low-saturation scanner background to pure white.

    Mushaf pages are flat colours printed on paper; the scan's paper grain is
    the main thing stopping lossless WebP from compressing well. Anything whose
    darkest channel is at or above ``threshold`` is background, so it becomes
    white.
    """
    import numpy as np

    array = np.asarray(image).astype("int16")
    background = array.min(axis=2) >= threshold
    array[background] = 255
    return Image.fromarray(array.astype("uint8"))


def save_webp(
    image: "Image.Image",
    destination: Path,
    *,
    encoder: str,
    colors: int,
    flatten_threshold: int,
    quality: int,
) -> int:
    prepared = flatten_paper(image, flatten_threshold) if flatten_threshold else image
    if encoder == "palette":
        prepared = prepared.quantize(
            colors=colors, method=Image.MEDIANCUT, dither=Image.NONE
        )
        prepared.save(destination, format="WEBP", lossless=True, method=6)
    else:
        prepared.save(destination, format="WEBP", quality=quality, method=6)
    return destination.stat().st_size


def convert(
    pdf_path: Path,
    output_dir: Path,
    pages: list[int],
    *,
    first_page: int,
    height: int,
    encoder: str,
    colors: int,
    flatten_threshold: int,
    quality: int,
) -> list[Path]:
    """Render ``pages`` (1-based output pages) starting at ``first_page``.

    Output page ``n`` maps to PDF page ``first_page + n - 1`` and is written as
    ``page_{n:03d}.webp`` so both editions line up page-for-page.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    document = pymupdf.open(pdf_path)
    try:
        total = document.page_count
        last = pages[-1] if pages else 0
        for number in pages:
            pdf_number = first_page + number - 1
            if pdf_number > total:
                raise SystemExit(
                    f"pdf has only {total} pages but page {pdf_number} "
                    f"(output page {number}) was requested"
                )
            image = render_page(document[pdf_number - 1], height)
            destination = output_dir / f"page_{number:03d}.webp"
            size = save_webp(
                image,
                destination,
                encoder=encoder,
                colors=colors,
                flatten_threshold=flatten_threshold,
                quality=quality,
            )
            written.append(destination)
            print(
                f"page {number:03d}/{last} (pdf {pdf_number}) -> "
                f"{destination.name} ({image.width}x{image.height}, {size / 1024:.0f} KB)"
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
        status = "OK" if total_mb < TARGET_TOTAL_MB else "ABOVE the 35 MB target"
        print(f"target < 35 MB: {status}")
    else:
        print(f"note: expected {EXPECTED_PAGES} pages for the full Madani Mushaf")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--edition",
        choices=sorted(PRESETS),
        default="standard",
        help="edition preset to apply (default: standard)",
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--input", type=Path, help="path to a local Mushaf PDF")
    source.add_argument("--url", help="public-domain Mushaf PDF URL to download")
    parser.add_argument(
        "--output",
        type=Path,
        help="directory for the WebP pages (default: assets/mushaf/<edition>)",
    )
    parser.add_argument(
        "--cache",
        type=Path,
        help="where a --url download is cached (default: tools/cache/<edition>.pdf)",
    )
    parser.add_argument(
        "--first-page",
        type=int,
        help="PDF page that holds Qur'an page 1 (overrides the preset)",
    )
    parser.add_argument("--height", type=int, help="render height in pixels")
    parser.add_argument(
        "--encoder",
        choices=("palette", "lossy"),
        help="palette = flat-colour lossless WebP (smaller); lossy = quality WebP",
    )
    parser.add_argument("--colors", type=int, help="palette size for the palette encoder")
    parser.add_argument(
        "--flatten-threshold",
        type=int,
        help="darkest-channel level at/above which pixels become white (0 disables)",
    )
    parser.add_argument("--quality", type=int, default=82, help="lossy WebP quality")
    parser.add_argument(
        "--pages",
        help="1-based output page selection to render, e.g. '1-10' or '1,5,9'",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    require_dependencies()
    args = build_parser().parse_args(argv)
    preset = PRESETS[args.edition]

    first_page = args.first_page if args.first_page is not None else preset.first_page
    height = args.height if args.height is not None else preset.height
    encoder = args.encoder if args.encoder is not None else "palette"
    colors = args.colors if args.colors is not None else preset.colors
    flatten_threshold = (
        args.flatten_threshold
        if args.flatten_threshold is not None
        else preset.flatten_threshold
    )
    output = args.output if args.output else preset.default_output
    cache = (
        args.cache
        if args.cache
        else REPO_ROOT / "tools" / "cache" / preset.cache_name
    )

    pdf_path = args.input if args.input else download_pdf(args.url, cache)
    if not pdf_path.exists():
        raise SystemExit(f"pdf not found: {pdf_path}")

    with pymupdf.open(pdf_path) as document:
        total = document.page_count
    available = max(0, total - first_page + 1)
    print(
        f"{pdf_path.name}: {total} pages; edition={preset.name} "
        f"first_page={first_page} -> {available} Qur'an pages available"
    )

    pages = parse_pages(args.pages, min(EXPECTED_PAGES, available))
    written = convert(
        pdf_path,
        output,
        pages,
        first_page=first_page,
        height=height,
        encoder=encoder,
        colors=colors,
        flatten_threshold=flatten_threshold,
        quality=args.quality,
    )
    report(output, written)
    return 0


if __name__ == "__main__":
    sys.exit(main())
