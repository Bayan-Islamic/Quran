"""Tests for tools/process_mushaf_pdf.py.

Run with the standard library only:

    python3 -m unittest discover -s tools/tests -v

The tests build a small PDF in memory with pymupdf and check the WebP output.
They skip if the optional dependencies are missing.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import process_mushaf_pdf as tool  # noqa: E402

try:
    import pymupdf  # noqa: F401
    from PIL import Image

    HAVE_DEPS = True
except ImportError:  # pragma: no cover
    HAVE_DEPS = False


def make_pdf(path: Path, pages: int, covers: int = 0) -> None:
    """Write a PDF with ``pages`` content pages preceded by ``covers`` blanks."""
    document = pymupdf.open()
    for index in range(covers):
        document.new_page(width=420, height=595)
    for index in range(pages):
        page = document.new_page(width=420, height=595)
        page.insert_text((60, 100), f"page {index + 1}", fontsize=24)
    document.save(path)
    document.close()


def convert(pdf: Path, out: Path, pages, **overrides):
    """Call ``tool.convert`` with a preset's defaults unless overridden."""
    preset = tool.PRESETS["standard"]
    kwargs = dict(
        first_page=1,
        height=preset.height,
        encoder="palette",
        colors=preset.colors,
        flatten_threshold=preset.flatten_threshold,
        quality=82,
    )
    kwargs.update(overrides)
    return tool.convert(pdf, out, pages, **kwargs)


class ParsePagesTest(unittest.TestCase):
    def test_none_selects_every_page(self):
        self.assertEqual(tool.parse_pages(None, 3), [1, 2, 3])

    def test_range_and_list_and_dedup(self):
        self.assertEqual(tool.parse_pages("1-3", 5), [1, 2, 3])
        self.assertEqual(tool.parse_pages("1,5,9", 10), [1, 5, 9])
        self.assertEqual(tool.parse_pages("3,3,1", 5), [1, 3])

    def test_out_of_range_is_rejected(self):
        with self.assertRaises(SystemExit):
            tool.parse_pages("0", 5)
        with self.assertRaises(SystemExit):
            tool.parse_pages("1-6", 5)


class PresetTest(unittest.TestCase):
    def test_both_editions_are_defined(self):
        self.assertEqual(set(tool.PRESETS), {"standard", "tajweed"})

    def test_standard_skips_cover_pages_and_tajweed_does_not(self):
        self.assertEqual(tool.PRESETS["standard"].first_page, 4)
        self.assertEqual(tool.PRESETS["tajweed"].first_page, 1)

    def test_presets_target_the_height_and_budget(self):
        for preset in tool.PRESETS.values():
            self.assertEqual(preset.height, 1260)
            self.assertLessEqual(preset.colors, 5)
        self.assertEqual(tool.TARGET_TOTAL_MB, 35.0)


@unittest.skipUnless(HAVE_DEPS, "pymupdf and Pillow are required")
class ConvertTest(unittest.TestCase):
    def test_converts_to_sequentially_named_webp_pages(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pdf = tmp_path / "mushaf.pdf"
            out = tmp_path / "out"
            make_pdf(pdf, 3)

            written = convert(pdf, out, [1, 2, 3])

            self.assertEqual(
                [p.name for p in written],
                ["page_001.webp", "page_002.webp", "page_003.webp"],
            )
            for path in written:
                with Image.open(path) as image:
                    self.assertEqual(image.format, "WEBP")
                    self.assertEqual(image.height, tool.PRESETS["standard"].height)

    def test_page_selection_skips_other_pages(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pdf = tmp_path / "mushaf.pdf"
            out = tmp_path / "out"
            make_pdf(pdf, 5)

            written = convert(pdf, out, [2, 4])

            self.assertEqual([p.name for p in written], ["page_002.webp", "page_004.webp"])
            self.assertFalse((out / "page_001.webp").exists())

    def test_first_page_offset_aligns_both_editions(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pdf = tmp_path / "mushaf.pdf"
            out = tmp_path / "out"
            # 3 cover pages, then content pages 1..3.
            make_pdf(pdf, 3, covers=3)

            written = convert(pdf, out, [1, 2, 3], first_page=4)

            self.assertEqual(
                [p.name for p in written],
                ["page_001.webp", "page_002.webp", "page_003.webp"],
            )

    def test_requesting_past_the_end_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pdf = tmp_path / "mushaf.pdf"
            make_pdf(pdf, 2, covers=3)
            with self.assertRaises(SystemExit):
                convert(pdf, tmp_path / "out", [3], first_page=4)

    def test_flatten_paper_turns_bright_background_white(self):
        image = Image.new("RGB", (4, 1))
        image.putdata([(250, 250, 250), (10, 10, 10), (250, 250, 240), (0, 90, 0)])
        flattened = tool.flatten_paper(image, 185)
        self.assertEqual(
            [flattened.getpixel((x, 0)) for x in range(4)],
            [(255, 255, 255), (10, 10, 10), (255, 255, 255), (0, 90, 0)],
        )

    def test_palette_encoder_limits_the_colour_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pdf = tmp_path / "mushaf.pdf"
            out = tmp_path / "out"
            make_pdf(pdf, 1)

            convert(pdf, out, [1], colors=4)

            with Image.open(out / "page_001.webp") as image:
                self.assertLessEqual(len(image.convert("RGB").getcolors(maxcolors=1 << 24)), 5)


if __name__ == "__main__":
    unittest.main()
