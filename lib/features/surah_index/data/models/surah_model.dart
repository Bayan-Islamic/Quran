import '../../domain/entities/surah.dart';

class SurahModel extends Surah {
  const SurahModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.type,
    required super.totalVerses,
    required super.pageNumber,
  });

  factory SurahModel.fromMap(Map<String, dynamic> map) {
    return SurahModel(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      type: map['type'] as String,
      totalVerses: map['total_verses'] as int,
      pageNumber: map['page_number'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'type': type,
      'total_verses': totalVerses,
      'page_number': pageNumber,
    };
  }
}
