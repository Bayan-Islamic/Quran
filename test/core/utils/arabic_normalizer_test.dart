import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/core/utils/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer', () {
    test('normalizes Alif variants correctly', () {
      expect(ArabicNormalizer.normalize('أحمد'), equals('احمد'));
      expect(ArabicNormalizer.normalize('إبراهيم'), equals('ابراهيم'));
      expect(ArabicNormalizer.normalize('آدم'), equals('ادم'));
      expect(ArabicNormalizer.normalize('ٱللَّهِ'), equals('الله'));
    });

    test('normalizes Taa Marbuta correctly', () {
      expect(ArabicNormalizer.normalize('الجمعة'), equals('الجمعه'));
      expect(ArabicNormalizer.normalize('رحمة'), equals('رحمه'));
    });

    test('strips diacritics and tashkeel', () {
      const input = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      expect(ArabicNormalizer.normalize(input), equals('بسم الله الرحمن الرحيم'));
    });

    test('handles empty and BOM strings', () {
      expect(ArabicNormalizer.normalize(''), equals(''));
      expect(ArabicNormalizer.normalize('\ufeff'), equals(''));
    });
  });
}
