import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int id;
  final int surahId;
  final int verseNumber;
  final String textUthmani;

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
        textSearchNormalised,
        pageNumber,
        juz,
        hizb,
      ];
}

