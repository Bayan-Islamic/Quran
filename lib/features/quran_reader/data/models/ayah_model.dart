import '../../../../core/utils/arabic_normalizer.dart';
import '../../domain/entities/ayah.dart';

class AyahModel extends Ayah {
  const AyahModel({
    required super.id,
    required super.surahId,
    required super.verseNumber,
    required super.textUthmani,
    super.textTajweed = '',
    required super.textSearchNormalised,
    required super.pageNumber,
    required super.juz,
    required super.hizb,
  });

  factory AyahModel.fromMap(Map<String, dynamic> map) {
    final textUthmani = map['text_uthmani'] as String;
    return AyahModel(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      verseNumber: map['verse_number'] as int,
      // Strip Quranic marks the bundled font cannot draw (the stray black dot).
      textUthmani: ArabicNormalizer.sanitizeForDisplay(textUthmani),
      // The markup is sanitised at build time, but keep the call so a stale or
      // hand-edited database still renders cleanly.
      textTajweed:
          ArabicNormalizer.sanitizeForDisplay((map['text_tajweed'] as String?) ?? ''),
      textSearchNormalised:
          (map['text_search_normalised'] as String?) ?? textUthmani,
      pageNumber: map['page_number'] as int,
      juz: map['juz'] as int,
      hizb: (map['hizb'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_id': surahId,
      'verse_number': verseNumber,
      'text_uthmani': textUthmani,
      'text_tajweed': textTajweed,
      'text_search_normalised': textSearchNormalised,
      'page_number': pageNumber,
      'juz': juz,
      'hizb': hizb,
    };
  }
}
