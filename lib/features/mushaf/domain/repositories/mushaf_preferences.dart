import '../entities/mushaf_edition.dart';

/// Persists the reader's Mushaf edition choice across launches.
abstract class MushafPreferences {
  Future<MushafEdition> getEdition();
  Future<void> setEdition(MushafEdition edition);
}
