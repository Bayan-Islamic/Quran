/// Result of [ArabicNormalizer.normalizeWithOffsets]: the folded [text] plus
/// [offsets], where `offsets[i]` is the index in the original string of the
/// character that produced `text[i]`.
class NormalizedText {
  final String text;
  final List<int> offsets;

  const NormalizedText(this.text, this.offsets);

  bool get isEmpty => text.isEmpty;
  int get length => text.length;
}

class ArabicNormalizer {
  static const String _bom = '\ufeff';
  static const String _tatweel = '\u0640';

  static final RegExp _alifVariants = RegExp(r'[أإآٱ]');
  static final RegExp _diacritics = RegExp(
    r'[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06dc\u06df-\u06e8\u06ea-\u06ed]',
  );
  static final RegExp _whitespace = RegExp(r'\s');

  /// Quranic annotation marks the bundled Uthmanic Hafs font cannot draw: it
  /// substitutes one oversized filled circle for all of them, which reads as a
  /// stray black dot. Each is mapped to a safe equivalent. Must stay
  /// byte-identical to `_UNSUPPORTED_GLYPH_MAP` in `tools/build_quran_db.py`.
  ///
  /// U+06DF SMALL HIGH ROUNDED ZERO becomes U+06E0 SMALL HIGH UPRIGHT
  /// RECTANGULAR ZERO (same position, correctly drawn). U+06E3, U+06EA, U+06EB
  /// and U+06ED have no same-position glyph and are dropped.
  static const Map<String, String> _unsupportedGlyphs = {
    '\u06df': '\u06e0',
    '\u06e3': '',
    '\u06ea': '',
    '\u06eb': '',
    '\u06ed': '',
  };

  /// Replaces Quranic marks the bundled font cannot render with safe
  /// equivalents. Every mapped code point is a diacritic, so the
  /// search-normalised form is unchanged.
  static String sanitizeForDisplay(String input) {
    if (input.isEmpty) return input;
    var text = input;
    _unsupportedGlyphs.forEach((broken, replacement) {
      if (text.contains(broken)) text = text.replaceAll(broken, replacement);
    });
    return text;
  }

  /// Folds Arabic text for search.
  ///
  /// Strips the BOM and tatweel, folds alif variants to bare alif, taa marbuta
  /// to heh and alef maksura to yeh, removes tashkeel/pause marks and collapses
  /// whitespace. Must stay byte-identical to `normalize_arabic` in
  /// `tools/build_quran_db.py`, which produces `text_search_normalised`.
  static String normalize(String input) {
    if (input.isEmpty) return input;
    String text = input.replaceAll(_bom, '').replaceAll(_tatweel, '');
    text = text.replaceAll(_alifVariants, 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll(_diacritics, '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Same folding as [normalize], but also returns the source offset of every
  /// folded character so a match in the normalised text can be highlighted in
  /// the still-diacritised display text.
  ///
  /// [sanitizeForDisplay] is applied first. It is one-to-one on every code
  /// point (each substitution replaces a single mark with at most one), so the
  /// offsets stay aligned with the sanitised text the reader actually renders.
  static NormalizedText normalizeWithOffsets(String input) {
    final source = sanitizeForDisplay(input);
    final buffer = StringBuffer();
    final offsets = <int>[];
    int? pendingSpace;

    for (int i = 0; i < source.length; i++) {
      final ch = source[i];
      if (ch == _bom || ch == _tatweel || _diacritics.hasMatch(ch)) continue;
      if (_whitespace.hasMatch(ch)) {
        if (buffer.isNotEmpty) pendingSpace ??= i;
        continue;
      }
      if (pendingSpace != null) {
        buffer.write(' ');
        offsets.add(pendingSpace);
        pendingSpace = null;
      }
      buffer.write(_fold(ch));
      offsets.add(i);
    }

    return NormalizedText(buffer.toString(), offsets);
  }

  static String _fold(String ch) {
    if (_alifVariants.hasMatch(ch)) return 'ا';
    if (ch == 'ة') return 'ه';
    if (ch == 'ى') return 'ي';
    return ch;
  }

  /// Whether [ch] is a combining mark (tashkeel, superscript alef or pause
  /// glyph) that carries no letter of its own. Used to extend a highlight so it
  /// also covers the vowel marks trailing the last matched letter.
  static bool isDiacritic(String ch) => _diacritics.hasMatch(ch);
}

