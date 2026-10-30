import 'package:equatable/equatable.dart';

/// Offline study content bundled with an ayah: the Arabic Tafsir Al-Muyassar
/// and the Saheeh International English translation.
class AyahContent extends Equatable {
  final int ayahId;
  final String tafsirMuyassar;
  final String translationEn;

  const AyahContent({
    required this.ayahId,
    required this.tafsirMuyassar,
    required this.translationEn,
  });

  bool get hasTafsir => tafsirMuyassar.trim().isNotEmpty;
  bool get hasTranslation => translationEn.trim().isNotEmpty;

  @override
  List<Object?> get props => [ayahId, tafsirMuyassar, translationEn];
}
