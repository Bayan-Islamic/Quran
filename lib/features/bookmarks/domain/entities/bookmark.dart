import 'package:equatable/equatable.dart';

class Bookmark extends Equatable {
  final int surahId;
  final String surahNameAr;
  final int verseNumber;
  final String updatedAt;

  const Bookmark({
    required this.surahId,
    required this.surahNameAr,
    required this.verseNumber,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [surahId, surahNameAr, verseNumber, updatedAt];
}
