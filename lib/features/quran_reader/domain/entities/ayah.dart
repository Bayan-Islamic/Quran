import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int id;
  final int surahId;
  final int verseNumber;
  final String textUthmani;
  final int pageNumber;
  final int juz;

  const Ayah({
    required this.id,
    required this.surahId,
    required this.verseNumber,
    required this.textUthmani,
    required this.pageNumber,
    required this.juz,
  });

  @override
  List<Object?> get props => [id, surahId, verseNumber, textUthmani, pageNumber, juz];
}
