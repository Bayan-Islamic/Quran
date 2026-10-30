import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/mushaf_edition.dart';
import '../../domain/repositories/mushaf_preferences.dart';

/// [MushafPreferences] backed by `shared_preferences`.
class MushafPreferencesImpl implements MushafPreferences {
  static const String keyEdition = 'mushaf_edition';

  final SharedPreferences sharedPreferences;

  MushafPreferencesImpl({required this.sharedPreferences});

  @override
  Future<MushafEdition> getEdition() async {
    final stored = sharedPreferences.getString(keyEdition);
    return MushafEdition.values.firstWhere(
      (edition) => edition.name == stored,
      orElse: () => MushafEdition.standard,
    );
  }

  @override
  Future<void> setEdition(MushafEdition edition) async {
    await sharedPreferences.setString(keyEdition, edition.name);
  }
}
