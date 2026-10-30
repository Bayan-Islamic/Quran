import '../entities/ayah_content.dart';

abstract class TafsirRepository {
  /// Returns the bundled Tafsir/translation for an ayah, or `null` when the
  /// ayah has no bundled content.
  Future<AyahContent?> getAyahContent(int ayahId);
}
