import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int id;
  final int surahId;
  final int verseNumber;
  final String textUthmani;

  /// Uthmani text annotated with `<tajweed class="...">` markup, sourced from
  /// the database's `text_tajweed` column and used by the colour-coded Tajweed
  /// mode. Empty when the edition is unavailable.
  final String textTajweed;

  /// Arabic-normalised copy of [textUthmani], sourced from the database's
  /// `text_search_normalised` column so search never normalises at runtime.
  final String textSearchNormalised;

  final int pageNumber;
  final int juz;
  final int hizb;

  const Ayah({
    required this.id,
    required this.surahId,
    required this.verseNumber,
    required this.textUthmani,
    this.textTajweed = '',
    required this.textSearchNormalised,
    required this.pageNumber,
    required this.juz,
    required this.hizb,
  });

  @override
  List<Object?> get props => [
        id,
        surahId,
        verseNumber,
        textUthmani,
        textTajweed,
        textSearchNormalised,
        pageNumber,
        juz,
        hizb,
      ];
}

