# بيان القرآن — Bayan Quran

An offline-first Flutter Quran reader. The app ships with the full Uthmani
text (114 surahs, 6,236 ayahs) in a bundled SQLite database, so it works with no
network connection. It runs on Android, iOS, desktop and the web.

## Features

- **Surah index** — all 114 surahs with Arabic/English names, revelation type
  and verse counts.
- **Reader** — Uthmani script in the `UthmanicHafs` font with a line height of
  `2.1` so tashkeel is never clipped, plus an adjustable font size.
- **Basmala handling** — Surah 1 keeps the Basmala as its first verse, Surah 9
  has none, and Surahs 2–114 show a single decorative `BasmalaHeader` with any
  duplicate Basmala stripped from verse 1.
- **Full-text search** — queries the precomputed `text_search_normalised`
  column and highlights the match inside the still-diacritised display text.
- **Bookmarks** — long-press a verse to remember the last read position.
- **Light/dark themes** with an emerald and gold palette.

## Architecture

Feature-first Clean Architecture. Each feature owns its `data`, `domain` and
`presentation` layers; shared infrastructure lives in `lib/core`.

```
lib/
  core/
    constants/          colours and shared constants
    database/           DatabaseHelper + per-platform SQLite bootstrap
    theme/              Material themes
    utils/              Arabic normaliser
  features/
    surah_index/        surah list
    quran_reader/       ayah reader
    search/             full-text search
    bookmarks/          last-read position
```

State management uses `flutter_bloc` cubits. The database is opened read-only
because the bundled asset never changes.

## Cross-platform SQLite

`sqflite` has no desktop or web implementation, so `lib/core/database/platform/`
picks a backend at compile time via a conditional export:

| Target                  | Backend                                |
| ----------------------- | -------------------------------------- |
| Android / iOS           | `sqflite` plugin                       |
| Linux / Windows / macOS | `sqflite_common_ffi`                   |
| Web                     | `sqflite_common_ffi_web` (wasm SQLite) |

The bundled `assets/quran.db` is seeded into a writable location (a file on
native/desktop, IndexedDB on the web) the first time the app runs.

### Web binaries

The web build needs two binaries in `web/`:

- `sqlite3.wasm` — SQLite compiled to WebAssembly
- `sqflite_sw.js` — the shared worker that hosts it

Both are committed so `flutter build web` works offline. Regenerate them with:

```bash
dart run sqflite_common_ffi_web:setup --force
```

## Getting started

```bash
flutter pub get
flutter analyze          # must report 0 issues
flutter test             # unit + widget tests
flutter run              # pick a device
flutter build web --release
```

## Database builder

`assets/quran.db` is generated, not hand-edited:

```bash
python3 tools/build_quran_db.py
```

The script downloads the Uthmani text and chapter metadata from the
[quran.com v4 API](https://api.quran.com), normalises the text for search,
strips the duplicate Basmala from verse 1 (except Surah 1), and writes:

- `surahs(id, name_ar, name_en, type, total_verses, start_page)`
- `ayahs(id, surah_id, verse_number, text_uthmani, text_search_normalised,
  page_number, juz, hizb)`

Responses are cached in `tools/cache/` (gitignored). Pass `--offline` to build
from the cache without network access.

### Arabic normalisation

The normaliser strips diacritics and tatweel, folds alif variants to bare alif,
`ة` to `ه` and `ى` to `ي`, and collapses whitespace. The Dart implementation in
`lib/core/utils/arabic_normalizer.dart` must stay byte-identical to
`normalize_arabic()` in `tools/build_quran_db.py`; a fixture-based test
(`test/fixtures/normalisation_cases.json`) guards the parity.

## Mushaf PDF pipeline

`tools/process_mushaf_pdf.py` turns a Madani Mushaf PDF into optimised WebP
pages for the authentic 604-page Mushaf mode. It renders each page at ~1260 px
height, encodes WebP at quality 82, names the files `page_001.webp` …
`page_604.webp`, and reports the total directory size (target: under 40 MB).

```bash
pip install pymupdf Pillow

# From a local PDF
python3 tools/process_mushaf_pdf.py --input mushaf.pdf --output assets/mushaf

# Download a public-domain 604-page Madani Mushaf PDF first
python3 tools/process_mushaf_pdf.py --url <pdf-url> --output assets/mushaf

# Render a subset while iterating
python3 tools/process_mushaf_pdf.py --input mushaf.pdf --pages 1-10
```

Options: `--input` / `--url` (mutually exclusive), `--output`, `--cache` (where
a `--url` download is cached) and `--pages` (a 1-based selection such as
`1-10` or `1,5,9`).

## Testing

```bash
flutter test
```

Tests run against the real bundled database through `sqflite_common_ffi`; the
database is never mocked. Coverage includes surah/ayah counts, the Basmala
rules, normaliser/Python parity, offset mapping, and search highlighting.

## License

See [LICENSE](LICENSE).
