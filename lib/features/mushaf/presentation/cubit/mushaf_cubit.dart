import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/mushaf_edition.dart';
import '../../domain/repositories/mushaf_preferences.dart';
import 'mushaf_state.dart';

/// Drives the page-by-page Mushaf reader: current edition, current page and
/// the persisted edition preference.
class MushafCubit extends Cubit<MushafState> {
  final MushafPreferences? preferences;

  MushafCubit({this.preferences})
      : super(const MushafInitial(edition: MushafEdition.standard));

  /// Restores the persisted edition, if one is configured.
  Future<void> loadPreferences() async {
    if (preferences == null) return;
    final edition = await preferences!.getEdition();
    emit(MushafInitial(edition: edition, pageNumber: state.pageNumber));
  }

  /// Verifies the bundled pages exist before the reader is opened.
  Future<bool> isAvailable() async {
    try {
      await rootBundle.load(
        MushafEdition.standard.pageAssetPath(1),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void goToPage(int pageNumber) {
    emit(MushafLoaded(
      edition: state.edition,
      pageNumber: _clamp(pageNumber),
    ));
  }

  void nextPage() => goToPage(state.pageNumber + 1);

  void previousPage() => goToPage(state.pageNumber - 1);

  /// Switches edition, keeping the current page so the reader stays in place.
  void setEdition(MushafEdition edition) {
    emit(MushafLoaded(edition: edition, pageNumber: state.pageNumber));
    preferences?.setEdition(edition);
  }

  void toggleEdition() {
    final next = state.edition == MushafEdition.standard
        ? MushafEdition.tajweed
        : MushafEdition.standard;
    setEdition(next);
  }

  static int _clamp(int pageNumber) =>
      pageNumber.clamp(1, MushafEdition.pageCount);
}
