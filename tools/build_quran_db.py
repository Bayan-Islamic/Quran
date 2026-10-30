#!/usr/bin/env python3
"""Build the offline Quran database bundled with Bayan Quran.

The script produces ``assets/quran.db`` from the Uthmani text published by
the Quran.com API (https://api.quran.com/api/v4).  Running it is only
necessary when the source data changes; the generated database is committed
so the app works fully offline.

Schema
------
``surahs``
    ``id`` (1-114), ``name_ar``, ``name_en``, ``type`` ("مكية"/"مدنية"),
    ``total_verses``, ``start_page``.

``ayahs``
    ``id`` (1-6236), ``surah_id``, ``verse_number``, ``text_uthmani``,
    ``text_tajweed``, ``text_search_normalised``, ``page_number``, ``juz``,
    ``hizb``.

``ayah_content``
    ``ayah_id`` (FK), ``tafsir_muyassar`` (Arabic), ``translation_en``
    (Saheeh International).  Kept in a side table so the hot ``ayahs`` rows
    stay small; the Tafsir/Translation sheet joins on demand.

The ``text_search_normalised`` column holds the Arabic-normalised form of
``text_uthmani`` so full-text search never has to normalise at runtime.  The
normalisation must stay byte-identical to
``lib/core/utils/arabic_normalizer.dart``.

``text_tajweed`` holds the same verse with ``<tajweed class="...">`` markup
from the ``uthmani_tajweed`` edition, used by the colour-coded Tajweed mode.
The ``<span class="end">N</span>`` verse markers are stripped (the reader draws
its own verse number) and the glyph sanitiser is applied, so the two text
columns stay visually consistent.

Usage::

    python3 tools/build_quran_db.py                 # build assets/quran.db
    python3 tools/build_quran_db.py --output out.db # custom destination
    python3 tools/build_quran_db.py --offline       # reuse tools/cache/
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE_DIR = Path(__file__).resolve().parent / "cache"
DEFAULT_OUTPUT = REPO_ROOT / "assets" / "quran.db"

VERSES_URL = (
    "https://api.quran.com/api/v4/verses/by_chapter/{chapter}"
    "?fields=text_uthmani,juz_number,hizb_number,page_number,rub_el_hizb_number"
    "&per_page=300&page=1"
)
CHAPTERS_URL = "https://api.quran.com/api/v4/chapters?language=en"
CHAPTERS_AR_URL = "https://api.quran.com/api/v4/chapters?language=ar"
TAJWEED_URL = (
    "https://api.quran.com/api/v4/quran/verses/uthmani_tajweed"
    "?chapter_number={chapter}"
)
# Saheeh International (resource 20), one chapter per request.
TRANSLATION_URL = (
    "https://api.quran.com/api/v4/quran/translations/20?chapter_number={chapter}"
)
# Tafsir Al-Muyassar (resource 16). The quran.com bulk endpoint returns an empty
# list, so the per-chapter JSON is taken from the community mirror that backs the
# tafsir API (github.com/spa5k/tafsir_api, itself generated from quran.com).
TAFSIR_MUYASSAR_URL = (
    "https://raw.githubusercontent.com/spa5k/tafsir_api/main"
    "/tafsir/ar-tafsir-muyassar/{chapter}.json"
)

USER_AGENT = "bayan-quran-db-builder/1.0 (+https://github.com/bayan-islamic/quran)"

EXPECTED_SURAHS = 114
EXPECTED_AYAHS = 6236
BASMALA = "بسم الله الرحمن الرحيم"

# Surah 1 carries the Basmala as verse 1; Surah 9 has no Basmala at all.
# Every other surah shows a decorative header and its first verse text must
# not repeat the Basmala.
SURAH_FATIHA = 1
SURAH_TAWBAH = 9

# Diacritics, Quranic annotation signs and pause marks (tashkeel + waqf).
_DIACRITICS = re.compile(
    "[\u0610-\u061a"
    "\u064b-\u065f"
    "\u0670"
    "\u06d6-\u06dc"
    "\u06df-\u06e8"
    "\u06ea-\u06ed]"
)
_ALIF_VARIANTS = re.compile("[أإآٱ]")
_TATWEEL = "\u0640"
_WHITESPACE = re.compile(r"\s+")

# The bundled KFGQPC Uthmanic Hafs font has no outline for these five Quranic
# annotation marks; it draws them all with one oversized filled circle, which
# shows up as a stray black dot in the reader. Map each to a safe equivalent:
#
#   U+06DF SMALL HIGH ROUNDED ZERO -> U+06E0 SMALL HIGH UPRIGHT RECTANGULAR ZERO
#     Same position and "zero" meaning, and the font draws it correctly.
#   U+06E3 SMALL LOW SEEN, U+06EA/U+06EB EMPTY CENTRE STOPS and U+06ED SMALL LOW
#     MEEM have no same-position glyph in this font, so they are dropped.
#
# Every mapped code point is a diacritic, so the search-normalised form is
# unaffected and highlight offsets stay aligned.
_UNSUPPORTED_GLYPH_MAP = {
    "\u06df": "\u06e0",
    "\u06e3": "",
    "\u06ea": "",
    "\u06eb": "",
    "\u06ed": "",
}


def sanitize_quranic_glyphs(text: str) -> str:
    """Replace Quranic marks the bundled font cannot draw with safe equivalents.

    Must stay byte-identical to ``ArabicNormalizer.sanitizeForDisplay`` in
    ``lib/core/utils/arabic_normalizer.dart``.
    """
    if not text:
        return text
    for broken, replacement in _UNSUPPORTED_GLYPH_MAP.items():
        if broken in text:
            text = text.replace(broken, replacement)
    return text


def normalize_arabic(text: str) -> str:
    """Normalise Arabic text for search.

    Mirrors ``ArabicNormalizer.normalize`` in the Dart sources: strip the BOM
    and tatweel, fold alif variants to bare alif, fold taa marbuta to heh and
    alef maksura to yeh, drop tashkeel/pause marks and collapse whitespace.
    """
    if not text:
        return text
    text = text.replace("\ufeff", "").replace(_TATWEEL, "")
    text = _ALIF_VARIANTS.sub("ا", text)
    text = text.replace("ة", "ه").replace("ى", "ي")
    text = _DIACRITICS.sub("", text)
    return _WHITESPACE.sub(" ", text).strip()


def strip_basmala_prefix(text: str) -> str:
    """Remove a leading Basmala from a first verse, keeping the rest intact.

    The comparison is done on the normalised text so it is independent of the
    exact diacritic form the source uses (e.g. ``بِسْمِ`` vs ``بِّسْمِ``); the
    returned string is sliced from the original so diacritics are preserved.
    """
    stripped = text.strip()
    if not normalize_arabic(stripped).startswith(BASMALA):
        return stripped
    words = stripped.split()
    for index in range(len(words)):
        if normalize_arabic(" ".join(words[: index + 1])) == BASMALA:
            return " ".join(words[index + 1 :]).strip()
    return stripped


_TAJWEED_END_MARKER = re.compile(r"<span class=end>\d+</span>\s*")
_TAG = re.compile(r"<[^>]*>")
# Footnote markers look like `<sup foot_note=195932>1</sup>`; the marker and its
# number are dropped together.
_SUP_ELEMENT = re.compile(r"<sup[^>]*>.*?</sup>", re.DOTALL)


def clean_tajweed_markup(text: str) -> str:
    """Strip non-tajweed markup from an ``uthmani_tajweed`` verse.

    Removes the ``<span class=end>N</span>`` verse marker (the reader draws its
    own verse number) and any stray ``>`` left by a malformed source tag (e.g.
    the orphan ``>`` in 32:3), then applies the shared glyph sanitiser so the
    Tajweed and plain columns render the same shapes.
    """
    text = _TAJWEED_END_MARKER.sub("", text)
    text = _strip_stray_gt(text)
    return sanitize_quranic_glyphs(text).strip()


def _strip_stray_gt(text: str) -> str:
    """Drop ``>`` characters that are not part of a well-formed ``<...>`` tag."""
    tags: list[str] = []

    def protect(match: re.Match[str]) -> str:
        tags.append(match.group(0))
        return f"\x00{len(tags) - 1}\x00"

    protected = _TAG.sub(protect, text).replace(">", "")
    return re.sub(r"\x00(\d+)\x00", lambda m: tags[int(m.group(1))], protected)


def _download(url: str, cache_file: Path, offline: bool) -> dict:
    if cache_file.exists():
        return json.loads(cache_file.read_text(encoding="utf-8"))
    if offline:
        raise SystemExit(f"cache miss for {url} and --offline was given ({cache_file})")
    print(f"downloading {url}")
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:  # noqa: S310
        payload = json.loads(response.read().decode("utf-8"))
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    return payload


def build_verses(offline: bool) -> list[tuple[int, int, str, int, int, int]]:
    rows: list[tuple[int, int, str, int, int, int]] = []
    for chapter in range(1, EXPECTED_SURAHS + 1):
        url = VERSES_URL.format(chapter=chapter)
        data = _download(url, CACHE_DIR / f"verses_{chapter:03d}.json", offline)
        for verse in data["verses"]:
            surah_id, verse_number = (int(part) for part in verse["verse_key"].split(":"))
            text = sanitize_quranic_glyphs(verse["text_uthmani"].strip())
            if surah_id not in (SURAH_FATIHA, SURAH_TAWBAH) and verse_number == 1:
                text = strip_basmala_prefix(text)
            rows.append(
                (
                    surah_id,
                    verse_number,
                    text,
                    verse["page_number"],
                    verse["juz_number"],
                    (verse["rub_el_hizb_number"] - 1) // 4 + 1,
                )
            )
    return rows


def build_tajweed(offline: bool) -> dict[str, str]:
    """Return ``verse_key -> tajweed markup`` from the uthmani_tajweed edition."""
    verses: dict[str, str] = {}
    for chapter in range(1, EXPECTED_SURAHS + 1):
        url = TAJWEED_URL.format(chapter=chapter)
        data = _download(url, CACHE_DIR / f"tajweed_{chapter:03d}.json", offline)
        for verse in data["verses"]:
            text = clean_tajweed_markup(verse["text_uthmani_tajweed"])
            surah_id, verse_number = (int(p) for p in verse["verse_key"].split(":"))
            if surah_id not in (SURAH_FATIHA, SURAH_TAWBAH) and verse_number == 1:
                text = strip_basmala_prefix(text)
            verses[verse["verse_key"]] = text
    return verses


def strip_html(text: str) -> str:
    """Reduce an HTML-ish translation/tafsir string to clean plain text.

    The Saheeh International translations carry ``<sup foot_note=...>N</sup>``
    footnote markers; the Tafsir Muyassar text carries ``<span class="green">``
    highlighting. Both are dropped, and the remaining HTML entities decoded.
    """
    text = _SUP_ELEMENT.sub("", text)
    text = _TAG.sub("", text)
    return (
        text.replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", '"')
        .replace("&#39;", "'")
        .replace("&nbsp;", " ")
        .strip()
    )


def build_translation(offline: bool) -> dict[str, str]:
    """Return ``verse_key -> Saheeh International translation`` (English).

    The bulk endpoint returns one entry per ayah in recitation order and does
    not echo the verse key, so the position supplies the verse number.
    """
    verses: dict[str, str] = {}
    for chapter in range(1, EXPECTED_SURAHS + 1):
        url = TRANSLATION_URL.format(chapter=chapter)
        data = _download(url, CACHE_DIR / f"translation_{chapter:03d}.json", offline)
        for index, verse in enumerate(data["translations"], start=1):
            verses[f"{chapter}:{index}"] = strip_html(verse["text"])
    return verses


def build_tafsir_muyassar(offline: bool) -> dict[str, str]:
    """Return ``verse_key -> Tafsir Al-Muyassar`` (Arabic) for every ayah."""
    verses: dict[str, str] = {}
    for chapter in range(1, EXPECTED_SURAHS + 1):
        url = TAFSIR_MUYASSAR_URL.format(chapter=chapter)
        data = _download(url, CACHE_DIR / f"muyassar_{chapter:03d}.json", offline)
        for entry in data:
            key = f"{entry['surah']}:{entry['ayah']}"
            verses[key] = strip_html(entry["text"])
    return verses


def build_surahs(offline: bool) -> list[tuple[int, str, str, str, int, int]]:
    en = _download(CHAPTERS_URL, CACHE_DIR / "chapters_en.json", offline)["chapters"]
    ar = _download(CHAPTERS_AR_URL, CACHE_DIR / "chapters_ar.json", offline)["chapters"]
    ar_names = {chapter["id"]: chapter["name_arabic"] for chapter in ar}

    rows: list[tuple[int, str, str, str, int, int]] = []
    for chapter in en:
        chapter_id = chapter["id"]
        revelation = chapter["revelation_place"]
        rows.append(
            (
                chapter_id,
                ar_names[chapter_id],
                chapter["name_simple"],
                "مكية" if revelation == "makkah" else "مدنية",
                chapter["verses_count"],
                chapter["pages"][0],
            )
        )
    return rows


def write_database(
    surahs: list[tuple[int, str, str, str, int, int]],
    verses: list[tuple[int, int, str, int, int, int]],
    tajweed: dict[str, str],
    translation: dict[str, str],
    tafsir: dict[str, str],
    output: Path,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()

    connection = sqlite3.connect(output)
    try:
        connection.executescript(
            """
            PRAGMA page_size = 4096;
            PRAGMA user_version = 0;

            CREATE TABLE surahs (
                id            INTEGER PRIMARY KEY,
                name_ar       TEXT    NOT NULL,
                name_en       TEXT    NOT NULL,
                type          TEXT    NOT NULL,
                total_verses  INTEGER NOT NULL,
                start_page    INTEGER NOT NULL
            );

            CREATE TABLE ayahs (
                id                      INTEGER PRIMARY KEY,
                surah_id                INTEGER NOT NULL,
                verse_number            INTEGER NOT NULL,
                text_uthmani            TEXT    NOT NULL,
                text_tajweed            TEXT    NOT NULL,
                text_search_normalised  TEXT    NOT NULL,
                page_number             INTEGER NOT NULL,
                juz                     INTEGER NOT NULL,
                hizb                    INTEGER NOT NULL,
                FOREIGN KEY (surah_id) REFERENCES surahs (id)
            );

            CREATE INDEX idx_ayahs_surah ON ayahs (surah_id, verse_number);
            CREATE INDEX idx_ayahs_page  ON ayahs (page_number);
            CREATE INDEX idx_ayahs_juz   ON ayahs (juz);
            CREATE INDEX idx_ayahs_hizb  ON ayahs (hizb);
            CREATE INDEX idx_ayahs_search ON ayahs (text_search_normalised);

            CREATE TABLE ayah_content (
                ayah_id         INTEGER PRIMARY KEY,
                tafsir_muyassar TEXT    NOT NULL,
                translation_en  TEXT    NOT NULL,
                FOREIGN KEY (ayah_id) REFERENCES ayahs (id)
            );
            """
        )

        connection.executemany(
            "INSERT INTO surahs (id, name_ar, name_en, type, total_verses, start_page) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            surahs,
        )

        connection.executemany(
            "INSERT INTO ayahs (id, surah_id, verse_number, text_uthmani, "
            "text_tajweed, text_search_normalised, page_number, juz, hizb) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [
                (
                    index,
                    surah_id,
                    verse_number,
                    text,
                    tajweed.get(f"{surah_id}:{verse_number}", ""),
                    normalize_arabic(text),
                    page,
                    juz,
                    hizb,
                )
                for index, (surah_id, verse_number, text, page, juz, hizb) in enumerate(
                    verses, start=1
                )
            ],
        )

        connection.executemany(
            "INSERT INTO ayah_content (ayah_id, tafsir_muyassar, translation_en) "
            "VALUES (?, ?, ?)",
            [
                (
                    index,
                    tafsir.get(f"{surah_id}:{verse_number}", ""),
                    translation.get(f"{surah_id}:{verse_number}", ""),
                )
                for index, (surah_id, verse_number, *_rest) in enumerate(verses, start=1)
            ],
        )

        connection.commit()
        connection.execute("VACUUM")
    finally:
        connection.close()


def validate(
    surahs: list[tuple[int, str, str, str, int, int]],
    verses: list[tuple[int, int, str, int, int, int]],
    tajweed: dict[str, str],
    translation: dict[str, str],
    tafsir: dict[str, str],
) -> None:
    errors: list[str] = []
    if len(surahs) != EXPECTED_SURAHS:
        errors.append(f"expected {EXPECTED_SURAHS} surahs, got {len(surahs)}")
    if len(verses) != EXPECTED_AYAHS:
        errors.append(f"expected {EXPECTED_AYAHS} ayahs, got {len(verses)}")
    if len(tajweed) != EXPECTED_AYAHS:
        errors.append(f"expected {EXPECTED_AYAHS} tajweed verses, got {len(tajweed)}")
    if len(translation) != EXPECTED_AYAHS:
        errors.append(
            f"expected {EXPECTED_AYAHS} translation verses, got {len(translation)}"
        )
    if len(tafsir) != EXPECTED_AYAHS:
        errors.append(f"expected {EXPECTED_AYAHS} tafsir verses, got {len(tafsir)}")

    verse_keys = {f"{surah_id}:{verse_number}" for surah_id, verse_number, *_ in verses}
    for label, table in (("translation", translation), ("tafsir", tafsir)):
        for key in sorted(verse_keys - table.keys()):
            errors.append(f"{label} missing for verse {key}")
        for key in sorted(table.keys() - verse_keys):
            errors.append(f"{label} has an unexpected verse {key}")

    per_surah: dict[int, int] = {}
    for surah_id, _, _, _, _, _ in verses:
        per_surah[surah_id] = per_surah.get(surah_id, 0) + 1
    for surah_id, _, _, _, total_verses, _ in surahs:
        if per_surah.get(surah_id, 0) != total_verses:
            errors.append(
                f"surah {surah_id}: declared {total_verses} verses, found "
                f"{per_surah.get(surah_id, 0)}"
            )

    for surah_id, verse_number, text, *_ in verses:
        if surah_id in (SURAH_FATIHA, SURAH_TAWBAH) or verse_number != 1:
            continue
        if normalize_arabic(text).startswith(BASMALA):
            errors.append(f"verse {surah_id}:1 still carries a Basmala prefix")

    for surah_id, verse_number, text, *_ in verses:
        for mark in _UNSUPPORTED_GLYPH_MAP:
            if mark in text:
                errors.append(
                    f"verse {surah_id}:{verse_number} still contains the "
                    f"unsupported glyph U+{ord(mark):04X}"
                )
                break

    for verse_key, text in tajweed.items():
        if not text:
            errors.append(f"tajweed text missing for verse {verse_key}")
            continue
        if "<span" in text:
            errors.append(f"tajweed verse {verse_key} still contains a <span> marker")
        if "<" in text and not re.search(r"<tajweed class=[^>]+>", text):
            errors.append(f"tajweed verse {verse_key} has malformed markup")
        for mark in _UNSUPPORTED_GLYPH_MAP:
            if mark in text:
                errors.append(
                    f"tajweed verse {verse_key} still contains the unsupported "
                    f"glyph U+{ord(mark):04X}"
                )
                break

    if errors:
        raise SystemExit("validation failed:\n  - " + "\n  - ".join(errors))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--offline",
        action="store_true",
        help="use cached API responses instead of downloading",
    )
    args = parser.parse_args()

    surahs = build_surahs(args.offline)
    verses = build_verses(args.offline)
    tajweed = build_tajweed(args.offline)
    translation = build_translation(args.offline)
    tafsir = build_tafsir_muyassar(args.offline)
    validate(surahs, verses, tajweed, translation, tafsir)
    write_database(surahs, verses, tajweed, translation, tafsir, args.output)
    size_mb = os.path.getsize(args.output) / (1024 * 1024)
    print(
        f"wrote {args.output} ({size_mb:.2f} MB) - "
        f"{len(surahs)} surahs, {len(verses)} ayahs, "
        f"{len(tafsir)} tafsir, {len(translation)} translations"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
