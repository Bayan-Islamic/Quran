import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bayan_quran/features/mushaf/domain/entities/mushaf_edition.dart';
import 'package:bayan_quran/features/mushaf/presentation/cubit/mushaf_cubit.dart';
import 'package:bayan_quran/features/mushaf/presentation/pages/mushaf_page.dart';

void main() {
  Widget buildTestWidget({int initialPage = 1}) {
    return MaterialApp(
      home: BlocProvider<MushafCubit>(
        create: (_) => MushafCubit(),
        child: MushafPage(initialPage: initialPage),
      ),
    );
  }

  testWidgets('opens at the requested page and shows the Arabic page counter',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 42));
    await tester.pump();

    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    expect(cubit.state.pageNumber, 42);
    // The counter appears both in the app bar ("صفحة ٤٢ / ٦٠٤") and in the
    // bottom control bar ("٤٢").
    expect(find.textContaining('٤٢'), findsWidgets);
    expect(find.textContaining('صفحة ٤٢'), findsOneWidget);
  });

  testWidgets('the bottom control bar exposes a page slider', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 1));
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 1);
    expect(slider.max, MushafEdition.pageCount.toDouble());
    expect(slider.value, 1);

    // Dragging the slider moves the reader to a new page.
    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    await tester.drag(find.byType(Slider), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(cubit.state.pageNumber, greaterThan(1));
  });

  testWidgets('swiping forward advances the page', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 1));
    await tester.pump();

    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    expect(cubit.state.pageNumber, 1);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(cubit.state.pageNumber, 2);
  });

  testWidgets('the palette action toggles between the two editions',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    expect(cubit.state.edition, MushafEdition.standard);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    expect(cubit.state.edition, MushafEdition.tajweed);
    expect(find.byIcon(Icons.palette), findsOneWidget);
  });

  testWidgets('renders the image for the current edition and page',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 3));
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      MushafEdition.standard.pageAssetPath(3),
    );
  });

  testWidgets('switching edition requests the other edition assets',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 3));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      MushafEdition.tajweed.pageAssetPath(3),
    );
  });
}
