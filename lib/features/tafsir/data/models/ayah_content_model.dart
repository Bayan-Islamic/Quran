import '../../domain/entities/ayah_content.dart';

class AyahContentModel extends AyahContent {
  const AyahContentModel({
    required super.ayahId,
    required super.tafsirMuyassar,
    required super.translationEn,
  });

  factory AyahContentModel.fromMap(Map<String, dynamic> map) {
    return AyahContentModel(
      ayahId: map['ayah_id'] as int,
      tafsirMuyassar: (map['tafsir_muyassar'] as String?) ?? '',
      translationEn: (map['translation_en'] as String?) ?? '',
    );
  }
}
