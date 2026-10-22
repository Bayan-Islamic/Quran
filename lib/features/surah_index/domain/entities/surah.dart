import 'package:equatable/equatable.dart';

class Surah extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String type; // Meccan / Medinan
  final int totalVerses;
  final int pageNumber;

  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    required this.totalVerses,
    required this.pageNumber,
  });

  @override
  List<Object?> get props => [id, nameAr, nameEn, type, totalVerses, pageNumber];
}
