import 'package:flutter/material.dart';

/// Maps Tajweed rule class names to the colours of the authentic Tajweed
/// Mushaf palette.
///
/// The bundled database uses the class names emitted by the Quran.com
/// `uthmani_tajweed` edition (for example `ham_wasl`, `madda_normal`). The
/// aliases from the published Tajweed specification (for example
/// `hamzat_wasl`, `madd_2`) are accepted as well so the parser keeps working
/// with either vocabulary.
class TajweedColors {
  TajweedColors._();

  // Madd (المدود) — reds and oranges.
  static const Color maddLong = Color(0xFF991B1B); // dark crimson
  static const Color maddConnected = Color(0xFFE11D48); // rose
  static const Color maddShort = Color(0xFFEA580C); // light coral

  // Ghunnah & Ikhfa (الغنة والإخفاء) — emerald.
  static const Color ghunnah = Color(0xFF059669);

  // Qalqalah (القلقلة) — cyan/sky.
  static const Color qalqalah = Color(0xFF0284C7);

  // Silent / assimilated (ما لا يُلفظ) — muted gray.
  static const Color silent = Color(0xFF94A3B8);

  /// Every rule colour, keyed by the class names that map to it. A class name
  /// missing from this map renders in the ambient text colour.
  static const Map<String, Color> _byClass = {
    // Madd — dark crimson: 6-count and necessary madd.
    'madd_6': maddLong,
    'madd_lazim': maddLong,
    'madda_necessary': maddLong,
    // Madd — rose: connected/separated and 4-5 count madd.
    'madd_muttasil': maddConnected,
    'madd_munfasil': maddConnected,
    'madd_45': maddConnected,
    'madda_obligatory': maddConnected,
    // Madd — light coral: natural and permissible madd.
    'madd_2': maddShort,
    'madd_regular': maddShort,
    'madda_normal': maddShort,
    'madda_permissible': maddShort,
    // Ghunnah & ikhfa (nasalisation).
    'ghunnah': ghunnah,
    'ikhfa': ghunnah,
    'ikhafa': ghunnah,
    'ikhfa_shafawi': ghunnah,
    'ikhafa_shafawi': ghunnah,
    'idgham_ghunnah': ghunnah,
    'idgham_shafawi': ghunnah,
    'iqlab': ghunnah,
    'idgham_mutajanisayn': ghunnah,
    'idgham_mutaqaribayn': ghunnah,
    // Qalqalah (echo/bounce).
    'qlq': qalqalah,
    'qalqalah': qalqalah,
    'qalaqah': qalqalah,
    // Silent / assimilated.
    'hamzat_wasl': silent,
    'ham_wasl': silent,
    'lam_shamsiyyah': silent,
    'laam_shamsiyah': silent,
    'silent': silent,
    'slnt': silent,
    'idgham_wo_ghunnah': silent,
  };

  /// The colour for a Tajweed [className], or null when the rule is not in the
  /// palette (callers then keep the ambient text colour).
  static Color? colorFor(String className) => _byClass[className.trim()];

  /// The class names in [group] order, for building the in-app colour guide.
  static const List<TajweedLegendEntry> legend = [
    TajweedLegendEntry('المدود', 'Madd (elongation)', maddLong),
    TajweedLegendEntry('المد المتصل/المنفصل', 'Connected / separated madd',
        maddConnected),
    TajweedLegendEntry('المد الطبيعي', 'Natural madd', maddShort),
    TajweedLegendEntry('الغنة والإخفاء', 'Ghunnah / Ikhfa (nasalisation)',
        ghunnah),
    TajweedLegendEntry('القلقلة', 'Qalqalah (echo)', qalqalah),
    TajweedLegendEntry('ما لا يُلفظ', 'Silent / assimilated', silent),
  ];
}

/// A single row of the in-app Tajweed colour guide.
class TajweedLegendEntry {
  final String labelAr;
  final String labelEn;
  final Color color;

  const TajweedLegendEntry(this.labelAr, this.labelEn, this.color);
}

/// Builds a coloured [TextSpan] tree from `uthmani_tajweed` markup.
///
/// The markup is a flat sequence of `<tajweed class="...">…</tajweed>` runs
/// with plain text between them. The parser is deliberately tolerant: it uses a
/// stack so nested tags take the innermost colour, and it never throws on
/// malformed input — unclosed tags are closed at end-of-text, orphan closing
/// tags are ignored, and unknown class names fall back to [defaultColor].
class TajweedTextSpan {
  TajweedTextSpan._();

  static const String fontFamily = 'UthmanicHafs';
  static const List<String> fontFamilyFallback = ['Amiri', 'Arial', 'sans-serif'];
  static const double lineHeight = 2.1;

  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    height: lineHeight,
  );

  /// Parses [markup] into a [TextSpan] styled with the Tajweed palette.
  ///
  /// When [markup] contains no tags, the whole string is returned as one span
  /// so callers can use this for both Tajweed and plain verses.
  static TextSpan build(
    String markup, {
    required double fontSize,
    required Color defaultColor,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
  }) {
    final base = _base.copyWith(
      fontSize: fontSize,
      color: defaultColor,
      fontWeight: fontWeight,
      height: height ?? lineHeight,
    );

    final children = <InlineSpan>[];
    // Each frame is the colour that applies to text emitted while it is open.
    // A frame inherits the enclosing colour when its own class is unknown.
    final stack = <Color?>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) return;
      final color = stack.isEmpty ? null : stack.last;
      children.add(TextSpan(
        text: buffer.toString(),
        style: color == null ? null : base.copyWith(color: color),
      ));
      buffer.clear();
    }

    var i = 0;
    while (i < markup.length) {
      final ch = markup[i];
      if (ch != '<') {
        buffer.write(ch);
        i++;
        continue;
      }

      final close = markup.indexOf('>', i);
      if (close == -1) {
        // No closing bracket: the rest is literal text.
        buffer.write(markup.substring(i));
        break;
      }

      final tag = markup.substring(i, close + 1);
      if (tag.startsWith('</')) {
        flush();
        if (stack.isNotEmpty) stack.removeLast();
      } else if (tag.startsWith('<!--') || tag.startsWith('<!')) {
        // Comment or declaration: ignore.
      } else {
        flush();
        final color = _classOf(tag);
        final resolved = color == null ? null : TajweedColors.colorFor(color);
        stack.add(resolved ?? (stack.isEmpty ? null : stack.last));
      }
      i = close + 1;
    }
    flush();

    return TextSpan(style: base, children: children);
  }

  /// Extracts the class name from an opening tag such as
  /// `<tajweed class=ham_wasl>` or `<tajweed class="ham_wasl">`.
  static String? _classOf(String tag) {
    final match = RegExp(r'''class\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''')
        .firstMatch(tag);
    if (match == null) return null;
    return match.group(1) ?? match.group(2) ?? match.group(3);
  }
}
