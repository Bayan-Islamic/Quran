import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/features/quran_reader/presentation/widgets/tajweed_text_span.dart';

/// Flattens a parsed span tree into `(text, color)` pairs, treating a null
/// style as "inherits the default colour".
List<(String, Color?)> _leaves(TextSpan root) {
  final out = <(String, Color?)>[];
  void walk(InlineSpan span, Color? inherited) {
    if (span is TextSpan) {
      final color = span.style?.color ?? inherited;
      if (span.text != null) out.add((span.text!, color));
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child, color);
      }
    }
  }

  walk(root, root.style?.color);
  return out;
}

TextSpan _parse(String markup, {Color defaultColor = Colors.black}) {
  return TajweedTextSpan.build(
    markup,
    fontSize: 24,
    defaultColor: defaultColor,
  );
}

void main() {
  group('TajweedTextSpan parsing', () {
    test('parses a simple tagged run into a coloured span', () {
      final root = _parse('قُلْ <tajweed class=qalaqah>د</tajweed>ٌ');
      final leaves = _leaves(root);
      expect(leaves.map((l) => l.$1).join(), equals('قُلْ دٌ'));
      final qalqalah = leaves.firstWhere((l) => l.$1 == 'د');
      expect(qalqalah.$2, equals(TajweedColors.qalqalah));
      // Untagged text keeps the default colour.
      expect(leaves.firstWhere((l) => l.$1 == 'قُلْ ').$2,
          equals(Colors.black));
    });

    test('parses quoted class attributes as well as unquoted', () {
      final quoted = _leaves(_parse('<tajweed class="ghunnah">نّ</tajweed>'));
      expect(quoted.single.$2, equals(TajweedColors.ghunnah));

      final single = _leaves(_parse("<tajweed class='ghunnah'>نّ</tajweed>"));
      expect(single.single.$2, equals(TajweedColors.ghunnah));
    });

    test('maps every documented class name to the Tajweed palette', () {
      const expectations = <String, Color>{
        'madd_6': TajweedColors.maddLong,
        'madd_lazim': TajweedColors.maddLong,
        'madd_muttasil': TajweedColors.maddConnected,
        'madd_munfasil': TajweedColors.maddConnected,
        'madd_45': TajweedColors.maddConnected,
        'madd_2': TajweedColors.maddShort,
        'madd_regular': TajweedColors.maddShort,
        'ghunnah': TajweedColors.ghunnah,
        'ikhfa': TajweedColors.ghunnah,
        'idgham_ghunnah': TajweedColors.ghunnah,
        'iqlab': TajweedColors.ghunnah,
        'qlq': TajweedColors.qalqalah,
        'qalqalah': TajweedColors.qalqalah,
        'hamzat_wasl': TajweedColors.silent,
        'lam_shamsiyyah': TajweedColors.silent,
        'silent': TajweedColors.silent,
      };
      for (final entry in expectations.entries) {
        expect(
          TajweedColors.colorFor(entry.key),
          equals(entry.value),
          reason: 'class ${entry.key}',
        );
      }
    });

    test('maps the quran.com API class names to the palette', () {
      const expectations = <String, Color>{
        'ham_wasl': TajweedColors.silent,
        'laam_shamsiyah': TajweedColors.silent,
        'slnt': TajweedColors.silent,
        'madda_normal': TajweedColors.maddShort,
        'madda_permissible': TajweedColors.maddShort,
        'madda_obligatory': TajweedColors.maddConnected,
        'madda_necessary': TajweedColors.maddLong,
        'ikhafa': TajweedColors.ghunnah,
        'qalaqah': TajweedColors.qalqalah,
        'idgham_wo_ghunnah': TajweedColors.silent,
      };
      for (final entry in expectations.entries) {
        expect(TajweedColors.colorFor(entry.key), equals(entry.value),
            reason: 'class ${entry.key}');
      }
    });

    test('unknown classes fall back to the default colour', () {
      final leaves = _leaves(_parse('<tajweed class=mystery>س</tajweed>'));
      expect(leaves.single.$2, equals(Colors.black));
    });
  });

  group('TajweedTextSpan robustness', () {
    test('handles unclosed tags by closing them at end of text', () {
      final root = _parse('ا<tajweed class=ghunnah>ب');
      final leaves = _leaves(root);
      expect(leaves.map((l) => l.$1).join(), equals('اب'));
      expect(leaves.last.$2, equals(TajweedColors.ghunnah));
    });

    test('ignores orphan closing tags', () {
      final leaves = _leaves(_parse('ا</tajweed>ب'));
      expect(leaves.map((l) => l.$1).join(), equals('اب'));
      expect(leaves.every((l) => l.$2 == Colors.black), isTrue);
    });

    test('treats a malformed opening tag literally without throwing', () {
      final leaves = _leaves(_parse('ا<tajweed class=ghunnahب'));
      // No ">" ever arrives, so the remainder is literal text.
      expect(leaves.map((l) => l.$1).join(), equals('ا<tajweed class=ghunnahب'));
    });

    test('nested tags use the innermost colour and restore the outer one', () {
      final leaves = _leaves(_parse(
        '<tajweed class=madd_2>ا<tajweed class=ghunnah>ب</tajweed>ج</tajweed>',
      ));
      expect(leaves.map((l) => l.$1).join(), equals('ابج'));
      expect(leaves[0].$2, equals(TajweedColors.maddShort));
      expect(leaves[1].$2, equals(TajweedColors.ghunnah));
      expect(leaves[2].$2, equals(TajweedColors.maddShort));
    });

    test('an unknown nested class inherits the enclosing colour', () {
      final leaves = _leaves(_parse(
        '<tajweed class=madd_2>ا<tajweed class=mystery>ب</tajweed></tajweed>',
      ));
      expect(leaves[1].$2, equals(TajweedColors.maddShort));
    });

    test('handles empty input and tag-only input', () {
      expect(_leaves(_parse('')), isEmpty);
      expect(_leaves(_parse('<tajweed class=ghunnah></tajweed>')), isEmpty);
    });

    test('plain text without tags becomes a single default-coloured span', () {
      final leaves = _leaves(_parse('الٓمٓ'));
      expect(leaves, hasLength(1));
      expect(leaves.single.$1, equals('الٓمٓ'));
      expect(leaves.single.$2, equals(Colors.black));
    });
  });

  group('TajweedTextSpan styling', () {
    test('applies the UthmanicHafs font and 2.1 line height', () {
      final root = _parse('<tajweed class=ghunnah>نّ</tajweed>');
      expect(root.style?.fontFamily, equals('UthmanicHafs'));
      expect(root.style?.height, equals(2.1));
      final child = (root.children!.single as TextSpan);
      expect(child.style?.fontFamily, equals('UthmanicHafs'));
      expect(child.style?.height, equals(2.1));
    });

    test('honours the requested font size', () {
      final root = TajweedTextSpan.build(
        'ا',
        fontSize: 30,
        defaultColor: Colors.black,
      );
      expect(root.style?.fontSize, equals(30));
    });
  });
}
