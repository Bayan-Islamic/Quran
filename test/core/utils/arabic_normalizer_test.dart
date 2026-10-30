import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/core/utils/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer', () {
    test('normalizes Alif variants correctly', () {
      expect(ArabicNormalizer.normalize('أحمد'), equals('احمد'));
      expect(ArabicNormalizer.normalize('إبراهيم'), equals('ابراهيم'));
      expect(ArabicNormalizer.normalize('آدم'), equals('ادم'));
      expect(ArabicNormalizer.normalize('ٱللَّهِ'), equals('الله'));
    });

    test('normalizes Taa Marbuta and Alef Maksura correctly', () {
      expect(ArabicNormalizer.normalize('الجمعة'), equals('الجمعه'));
      expect(ArabicNormalizer.normalize('رحمة'), equals('رحمه'));
      expect(ArabicNormalizer.normalize('موسى'), equals('موسي'));
    });

    test('strips diacritics and tashkeel', () {
      const input = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      expect(
          ArabicNormalizer.normalize(input), equals('بسم الله الرحمن الرحيم'));
    });

    test('strips tatweel and collapses whitespace', () {
      expect(ArabicNormalizer.normalize('ٱلْعَـٰلَمِينَ'), equals('العلمين'));
      expect(ArabicNormalizer.normalize('  a   b  '), equals('a b'));
      expect(ArabicNormalizer.normalize('على\nمسطرتين'), equals('علي مسطرتين'));
    });

    test('handles empty and BOM strings', () {
      expect(ArabicNormalizer.normalize(''), equals(''));
      expect(ArabicNormalizer.normalize('\ufeff'), equals(''));
    });

    test('sanitizeForDisplay replaces unsupported Quranic marks', () {
      // U+06DF (oversized black dot in the bundled font) -> U+06E0.
      expect(
        ArabicNormalizer.sanitizeForDisplay('أُو\u06dfلَـٰٓئِكَ'),
        equals('أُو\u06e0لَـٰٓئِكَ'),
      );
      // Marks with no same-position glyph are dropped.
      for (final mark in ['\u06e3', '\u06ea', '\u06eb', '\u06ed']) {
        expect(ArabicNormalizer.sanitizeForDisplay('a${mark}b'), equals('ab'));
      }
      // Supported text is untouched.
      const supported = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      expect(ArabicNormalizer.sanitizeForDisplay(supported), equals(supported));
      expect(ArabicNormalizer.sanitizeForDisplay(''), equals(''));
    });

    test('sanitizeForDisplay does not change the search-normalised form', () {
      const text = 'أُو\u06dfلَـٰٓئِكَ هُمُ ٱلْمُفْلِحُونَ\u06ed';
      expect(
        ArabicNormalizer.normalize(ArabicNormalizer.sanitizeForDisplay(text)),
        equals(ArabicNormalizer.normalize(text)),
      );
    });

    test('stays byte-identical to the Python builder normaliser', () {
      final fixture = File('test/fixtures/normalisation_cases.json');
      final cases = jsonDecode(fixture.readAsStringSync()) as List<dynamic>;
      expect(cases, isNotEmpty);
      for (final entry in cases.cast<Map<String, dynamic>>()) {
        expect(
          ArabicNormalizer.normalize(entry['input'] as String),
          equals(entry['normalized'] as String),
          reason: 'input: ${entry['input']}',
        );
      }
    });
  });

  group('ArabicNormalizer.normalizeWithOffsets', () {
    test('folds exactly like normalize', () {
      const samples = [
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
        'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ',
        '',
        '\ufeff',
      ];
      for (final sample in samples) {
        expect(
          ArabicNormalizer.normalizeWithOffsets(sample).text,
          equals(ArabicNormalizer.normalize(sample)),
          reason: 'sample: $sample',
        );
      }
    });

    test('offsets map each folded character back to the source', () {
      const input = 'بِسْمِ ٱللَّهِ';
      final normalized = ArabicNormalizer.normalizeWithOffsets(input);
      expect(normalized.text, equals('بسم الله'));
      expect(normalized.offsets.length, equals(normalized.text.length));
      for (var i = 0; i < normalized.offsets.length; i++) {
        final source = input[normalized.offsets[i]];
        if (source.trim().isEmpty) {
          expect(normalized.text[i], equals(' '));
        } else {
          expect(
              ArabicNormalizer.normalize(source), equals(normalized.text[i]));
        }
      }
    });

    test('offsets let a match be sliced out of the original text', () {
      const text = 'ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ ۛ فِيهِ';
      final normalized = ArabicNormalizer.normalizeWithOffsets(text);
      for (final query in ['ذلك', 'الكت', 'ريب', 'فيه']) {
        final match = normalized.text.indexOf(query);
        expect(match, isNonNegative, reason: 'query: $query');
        final start = normalized.offsets[match];
        final end = normalized.offsets[match + query.length - 1] + 1;
        expect(
          ArabicNormalizer.normalize(text.substring(start, end)),
          equals(query),
          reason: 'query: $query',
        );
      }
    });
  });
}
