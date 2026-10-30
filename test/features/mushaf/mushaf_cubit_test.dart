import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bayan_quran/features/mushaf/data/repositories/mushaf_preferences_impl.dart';
import 'package:bayan_quran/features/mushaf/domain/entities/mushaf_edition.dart';
import 'package:bayan_quran/features/mushaf/presentation/cubit/mushaf_cubit.dart';
import 'package:bayan_quran/features/mushaf/presentation/cubit/mushaf_state.dart';

void main() {
  group('MushafEdition', () {
    test('both editions are aligned page-for-page', () {
      expect(MushafEdition.values, hasLength(2));
      expect(MushafEdition.pageCount, 604);
    });

    test('page asset paths are zero-padded and edition-scoped', () {
      expect(
        MushafEdition.standard.pageAssetPath(1),
        'assets/mushaf/standard/page_001.webp',
      );
      expect(
        MushafEdition.tajweed.pageAssetPath(604),
        'assets/mushaf/tajweed/page_604.webp',
      );
      expect(
        MushafEdition.standard.pageAssetPath(42),
        'assets/mushaf/standard/page_042.webp',
      );
    });
  });

  group('MushafPreferencesImpl', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to the standard edition', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = MushafPreferencesImpl(sharedPreferences: prefs);
      expect(await repository.getEdition(), MushafEdition.standard);
    });

    test('persists the selected edition', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = MushafPreferencesImpl(sharedPreferences: prefs);
      await repository.setEdition(MushafEdition.tajweed);
      expect(await repository.getEdition(), MushafEdition.tajweed);
    });

    test('falls back to standard for an unknown stored value', () async {
      SharedPreferences.setMockInitialValues(
        {MushafPreferencesImpl.keyEdition: 'nonsense'},
      );
      final prefs = await SharedPreferences.getInstance();
      final repository = MushafPreferencesImpl(sharedPreferences: prefs);
      expect(await repository.getEdition(), MushafEdition.standard);
    });
  });

  group('MushafCubit', () {
    test('starts on the standard edition at page 1', () {
      final cubit = MushafCubit();
      expect(cubit.state, isA<MushafInitial>());
      expect(cubit.state.edition, MushafEdition.standard);
      expect(cubit.state.pageNumber, 1);
      cubit.close();
    });

    test('goToPage clamps to the 1..604 range', () {
      final cubit = MushafCubit();
      cubit.goToPage(0);
      expect(cubit.state.pageNumber, 1);
      cubit.goToPage(9999);
      expect(cubit.state.pageNumber, MushafEdition.pageCount);
      cubit.goToPage(250);
      expect(cubit.state.pageNumber, 250);
      cubit.close();
    });

    test('nextPage and previousPage step through the mushaf', () {
      final cubit = MushafCubit();
      cubit.goToPage(10);
      cubit.nextPage();
      expect(cubit.state.pageNumber, 11);
      cubit.previousPage();
      expect(cubit.state.pageNumber, 10);
      cubit.close();
    });

    test('switching edition keeps the current page', () {
      final cubit = MushafCubit();
      cubit.goToPage(300);
      cubit.setEdition(MushafEdition.tajweed);
      expect(cubit.state.edition, MushafEdition.tajweed);
      expect(cubit.state.pageNumber, 300);
      cubit.close();
    });

    test('toggleEdition flips between standard and tajweed', () {
      final cubit = MushafCubit();
      expect(cubit.state.edition, MushafEdition.standard);
      cubit.toggleEdition();
      expect(cubit.state.edition, MushafEdition.tajweed);
      cubit.toggleEdition();
      expect(cubit.state.edition, MushafEdition.standard);
      cubit.close();
    });

    test('restores the persisted edition', () async {
      SharedPreferences.setMockInitialValues(
        {MushafPreferencesImpl.keyEdition: MushafEdition.tajweed.name},
      );
      final prefs = await SharedPreferences.getInstance();
      final cubit = MushafCubit(
        preferences: MushafPreferencesImpl(sharedPreferences: prefs),
      );
      await cubit.loadPreferences();
      expect(cubit.state.edition, MushafEdition.tajweed);
      cubit.close();
    });

    test('setEdition persists the choice', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = MushafCubit(
        preferences: MushafPreferencesImpl(sharedPreferences: prefs),
      );
      cubit.setEdition(MushafEdition.tajweed);
      // Give the fire-and-forget write a turn to complete.
      await Future<void>.delayed(Duration.zero);
      expect(prefs.getString(MushafPreferencesImpl.keyEdition), 'tajweed');
      cubit.close();
    });
  });
}
