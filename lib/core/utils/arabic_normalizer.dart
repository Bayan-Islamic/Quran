class ArabicNormalizer {
  static const String _bom = '\ufeff';

  static String normalize(String input) {
    if (input.isEmpty) return input;
    String text = input.replaceAll(_bom, '');
    text = text.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'),
      '',
    );
    return text;
  }
}
