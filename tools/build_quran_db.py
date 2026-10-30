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
    ``text_search_normalised``, ``page_number``, ``juz``, ``hizb``.

The ``text_search_normalised`` column holds the Arabic-normalised form of
``text_uthmani`` so full-text search never has to normalise at runtime.  The
normalisation must stay byte-identical to
``lib/core/utils/arabic_normalizer.dart``.

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
            text = verse["text_uthmani"].strip()
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
            """
        )

        connection.executemany(
            "INSERT INTO surahs (id, name_ar, name_en, type, total_verses, start_page) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            surahs,
        )

        connection.executemany(
            "INSERT INTO ayahs (id, surah_id, verse_number, text_uthmani, "
            "text_search_normalised, page_number, juz, hizb) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [
                (index, surah_id, verse_number, text, normalize_arabic(text), page, juz, hizb)
                for index, (surah_id, verse_number, text, page, juz, hizb) in enumerate(
                    verses, start=1
                )
            ],
        )

        connection.commit()
        connection.execute("VACUUM")
    finally:
        connection.close()


def validate(
    surahs: list[tuple[int, str, str, str, int, int]],
    verses: list[tuple[int, int, str, int, int, int]],
) -> None:
    errors: list[str] = []
    if len(surahs) != EXPECTED_SURAHS:
        errors.append(f"expected {EXPECTED_SURAHS} surahs, got {len(surahs)}")
    if len(verses) != EXPECTED_AYAHS:
        errors.append(f"expected {EXPECTED_AYAHS} ayahs, got {len(verses)}")

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
    validate(surahs, verses)
    write_database(surahs, verses, args.output)
    size_mb = os.path.getsize(args.output) / (1024 * 1024)
    print(
        f"wrote {args.output} ({size_mb:.2f} MB) - "
        f"{len(surahs)} surahs, {len(verses)} ayahs"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
