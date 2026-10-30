import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/quran_reader_preferences.dart';

/// [QuranReaderPreferences] backed by `shared_preferences`.
class QuranReaderPreferencesImpl implements QuranReaderPreferences {
  static const String keyTajweedMode = 'reader_tajweed_mode';

  final SharedPreferences sharedPreferences;

  QuranReaderPreferencesImpl({required this.sharedPreferences});

  @override
  Future<bool> getTajweedMode() async =>
      sharedPreferences.getBool(keyTajweedMode) ?? false;

  @override
  Future<void> setTajweedMode(bool enabled) async {
    await sharedPreferences.setBool(keyTajweedMode, enabled);
  }
}
