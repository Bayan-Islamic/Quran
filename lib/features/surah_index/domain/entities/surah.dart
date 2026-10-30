import 'package:equatable/equatable.dart';

class Surah extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;

  /// Revelation place, as stored in the database: "مكية" (Meccan) or "مدنية"
  /// (Medinan). Legacy fixtures may use the English spellings, which
  /// [isMeccan] also accepts.
  final String type;

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

  /// Whether this surah was revealed in Mecca (مكية) rather than Medina (مدنية).
  bool get isMeccan {
    final normalized = type.trim().toLowerCase();
    return normalized == 'مكية' ||
        normalized == 'meccan' ||
        normalized == 'makkah' ||
        normalized == 'makki';
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, type, totalVerses, pageNumber];
}
