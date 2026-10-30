/// Persists the reader's display preferences across launches.
abstract class QuranReaderPreferences {
  Future<bool> getTajweedMode();
  Future<void> setTajweedMode(bool enabled);
}
