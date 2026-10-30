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


def make_pdf(path: Path, pages: int) -> None:
    document = pymupdf.open()
    for index in range(pages):
        page = document.new_page(width=420, height=595)
        page.insert_text((60, 100), f"page {index + 1}", fontsize=24)
    document.save(path)
    document.close()


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


@unittest.skipUnless(HAVE_DEPS, "pymupdf and Pillow are required")
class ConvertTest(unittest.TestCase):
    def test_converts_to_sequentially_named_webp_pages(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pdf = tmp_path / "mushaf.pdf"
            out = tmp_path / "out"
            make_pdf(pdf, 3)

            written = tool.convert(pdf, out, [1, 2, 3])

            self.assertEqual(
                [p.name for p in written],
                ["page_001.webp", "page_002.webp", "page_003.webp"],
            )
            for path in written:
                with Image.open(path) as image:
                    self.assertEqual(image.format, "WEBP")
                    self.assertEqual(image.height, tool.TARGET_HEIGHT_PX)

    def test_page_selection_skips_other_pages(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pdf = tmp_path / "mushaf.pdf"
            out = tmp_path / "out"
            make_pdf(pdf, 5)

            written = tool.convert(pdf, out, [2, 4])

            self.assertEqual([p.name for p in written], ["page_002.webp", "page_004.webp"])
            self.assertFalse((out / "page_001.webp").exists())


if __name__ == "__main__":
    unittest.main()
