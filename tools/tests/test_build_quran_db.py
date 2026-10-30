"""Tests for tools/build_quran_db.py.

Run with the standard library only:

    python3 -m unittest discover -s tools/tests -v

These tests do not touch the network: they exercise the pure helpers only.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import build_quran_db as builder  # noqa: E402


class NormalizeArabicTest(unittest.TestCase):
    def test_folds_alif_variants(self):
        self.assertEqual(builder.normalize_arabic("أحمد"), "احمد")
        self.assertEqual(builder.normalize_arabic("إبراهيم"), "ابراهيم")
        self.assertEqual(builder.normalize_arabic("آدم"), "ادم")
        self.assertEqual(builder.normalize_arabic("ٱللَّهِ"), "الله")

    def test_folds_taa_marbuta_and_alef_maksura(self):
        self.assertEqual(builder.normalize_arabic("الجمعة"), "الجمعه")
        self.assertEqual(builder.normalize_arabic("موسى"), "موسي")

    def test_strips_diacritics_tatweel_and_whitespace(self):
        self.assertEqual(
            builder.normalize_arabic("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"),
            "بسم الله الرحمن الرحيم",
        )
        self.assertEqual(builder.normalize_arabic("ٱلْعَـٰلَمِينَ"), "العلمين")
        self.assertEqual(builder.normalize_arabic("  a   b  "), "a b")
        self.assertEqual(builder.normalize_arabic(""), "")


class StripBasmalaTest(unittest.TestCase):
    def test_removes_a_diacritised_prefix(self):
        text = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الٓمٓ"
        self.assertEqual(builder.strip_basmala_prefix(text), "الٓمٓ")

    def test_keeps_text_without_a_prefix(self):
        self.assertEqual(builder.strip_basmala_prefix("الٓمٓ"), "الٓمٓ")

    def test_removes_a_bare_prefix(self):
        self.assertEqual(
            builder.strip_basmala_prefix("بسم الله الرحمن الرحيم الحمد لله"),
            "الحمد لله",
        )


class SanitizeQuranicGlyphsTest(unittest.TestCase):
    def test_maps_the_rounded_zero_to_the_upright_rectangular_zero(self):
        # The bundled font cannot draw U+06DF and shows an oversized black dot;
        # U+06E0 is the same "zero" mark and renders correctly.
        self.assertEqual(builder.sanitize_quranic_glyphs("أُو\u06dfلَـٰٓئِكَ"),
                         "أُو\u06e0لَـٰٓئِكَ")

    def test_drops_marks_with_no_same_position_glyph(self):
        for mark in ("\u06e3", "\u06ea", "\u06eb", "\u06ed"):
            self.assertEqual(builder.sanitize_quranic_glyphs(f"a{mark}b"), "ab")

    def test_leaves_supported_text_untouched(self):
        text = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
        self.assertEqual(builder.sanitize_quranic_glyphs(text), text)

    def test_handles_empty_input(self):
        self.assertEqual(builder.sanitize_quranic_glyphs(""), "")

    def test_is_a_no_op_for_search_normalisation(self):
        # Every mapped code point is a diacritic, so the normalised form is
        # identical whether or not the glyphs were sanitised first.
        text = "أُو\u06dfلَـٰٓئِكَ هُمُ ٱلْمُفْلِحُونَ\u06ed"
        self.assertEqual(
            builder.normalize_arabic(builder.sanitize_quranic_glyphs(text)),
            builder.normalize_arabic(text),
        )


class CleanTajweedMarkupTest(unittest.TestCase):
    def test_strips_the_verse_end_marker(self):
        self.assertEqual(
            builder.clean_tajweed_markup(
                "قُلْ هُوَ <tajweed class=ham_wasl>ٱ</tajweed>للَّهُ "
                "<span class=end>١</span>"
            ),
            "قُلْ هُوَ <tajweed class=ham_wasl>ٱ</tajweed>للَّهُ",
        )

    def test_strips_a_stray_greater_than_from_a_malformed_tag(self):
        # 32:3 in the source has ">ٮٰ" where an opening tag should be.
        text = "ٱفْتَرَ>ٮٰ</tajweed>هُ"
        self.assertEqual(builder.clean_tajweed_markup(text), "ٱفْتَرَٮٰ</tajweed>هُ")

    def test_keeps_well_formed_tags_intact(self):
        text = "<tajweed class=qalaqah>د</tajweed>"
        self.assertEqual(builder.clean_tajweed_markup(text), text)

    def test_applies_the_glyph_sanitiser(self):
        self.assertEqual(
            builder.clean_tajweed_markup("أُو\u06dfلَ"),
            "أُو\u06e0لَ",
        )

    def test_handles_empty_input(self):
        self.assertEqual(builder.clean_tajweed_markup(""), "")


class ValidateTajweedTest(unittest.TestCase):
    """`validate` always checks the full corpus, so these fixtures build one."""

    @staticmethod
    def _corpus():
        # 113 surahs with one verse + surah 114 carrying the rest = 6236.
        counts = {i: 1 for i in range(1, 114)}
        counts[114] = builder.EXPECTED_AYAHS - 113
        surahs = [(i, "n", "n", "مكية", counts[i], 1) for i in range(1, 115)]
        verses = []
        tajweed = {}
        for surah_id, count in counts.items():
            for verse_number in range(1, count + 1):
                verses.append((surah_id, verse_number, "الٓمٓ", 1, 1, 1))
                tajweed[f"{surah_id}:{verse_number}"] = "الٓمٓ"
        return surahs, verses, tajweed

    def test_accepts_a_well_formed_corpus(self):
        surahs, verses, tajweed = self._corpus()
        builder.validate(surahs, verses, tajweed)

    def test_rejects_a_missing_tajweed_verse(self):
        surahs, verses, tajweed = self._corpus()
        del tajweed["2:1"]
        with self.assertRaises(SystemExit):
            builder.validate(surahs, verses, tajweed)

    def test_rejects_a_leftover_span_marker(self):
        surahs, verses, tajweed = self._corpus()
        tajweed["2:1"] = "الٓمٓ <span class=end>١</span>"
        with self.assertRaises(SystemExit):
            builder.validate(surahs, verses, tajweed)

    def test_rejects_an_empty_tajweed_verse(self):
        surahs, verses, tajweed = self._corpus()
        tajweed["2:1"] = ""
        with self.assertRaises(SystemExit):
            builder.validate(surahs, verses, tajweed)

    def test_rejects_a_remaining_unsupported_glyph(self):
        surahs, verses, tajweed = self._corpus()
        tajweed["2:1"] = "ال\u06dfم"
        with self.assertRaises(SystemExit):
            builder.validate(surahs, verses, tajweed)


class ValidateTest(unittest.TestCase):
    @staticmethod
    def _surahs():
        return [(i, "n", "n", "مكية", 1, 1) for i in range(1, 115)]

    @staticmethod
    def _verses():
        # One verse per surah keeps the declared and actual counts consistent,
        # so only the aggregate-count checks are exercised.
        return [(i, 1, "الٓمٓ", 1, 1, 1) for i in range(1, 115)]

    @staticmethod
    def _tajweed():
        return {f"{i}:1": "الٓمٓ" for i in range(1, 115)}

    def test_rejects_the_wrong_surah_count(self):
        with self.assertRaises(SystemExit):
            builder.validate(
                [(1, "n", "n", "مكية", 1, 1)], self._verses(), self._tajweed()
            )

    def test_rejects_the_wrong_ayah_count(self):
        with self.assertRaises(SystemExit):
            builder.validate(self._surahs(), [], self._tajweed())

    def test_rejects_a_basmala_prefix_on_verse_one(self):
        verses = self._verses()
        verses[1] = (2, 1, "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الٓمٓ", 2, 1, 1)
        with self.assertRaises(SystemExit):
            builder.validate(self._surahs(), verses, self._tajweed())


if __name__ == "__main__":
    unittest.main()
