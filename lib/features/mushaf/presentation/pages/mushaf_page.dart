import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../domain/entities/mushaf_edition.dart';
import '../cubit/mushaf_cubit.dart';
import '../cubit/mushaf_state.dart';

/// Full-screen, page-by-page Mushaf reader backed by the bundled WebP pages.
///
/// The pages are swiped horizontally; both editions share the same page
/// numbering, so switching edition keeps the reader on the same Qur'an page.
class MushafPage extends StatefulWidget {
  /// 1-based Qur'an page to open at (defaults to Al-Fatihah).
  final int initialPage;

  const MushafPage({super.key, this.initialPage = 1});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late final PageController _pageController;

  /// Whether the top/bottom chrome (edition switcher, counter, slider) is
  /// shown. Tapping the page toggles it so the Mushaf can be read full-bleed.
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    final page = widget.initialPage.clamp(1, MushafEdition.pageCount);
    _pageController = PageController(initialPage: page - 1);
    context.read<MushafCubit>().goToPage(page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() =>
      setState(() => _controlsVisible = !_controlsVisible);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryEmeraldDark,
      appBar: _controlsVisible ? _buildAppBar() : null,
      body: BlocConsumer<MushafCubit, MushafState>(
        listener: (context, state) {
          if (_pageController.hasClients &&
              _pageController.page?.round() != state.pageNumber - 1) {
            _pageController.jumpToPage(state.pageNumber - 1);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: MushafEdition.pageCount,
                  onPageChanged: (index) =>
                      context.read<MushafCubit>().goToPage(index + 1),
                  itemBuilder: (context, index) {
                    return _MushafPageImage(
                      edition: state.edition,
                      pageNumber: index + 1,
                    );
                  },
                ),
              ),
              if (_controlsVisible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MushafControlsBar(
                    pageNumber: state.pageNumber,
                    onPageChanged: (page) =>
                        context.read<MushafCubit>().goToPage(page),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: BlocBuilder<MushafCubit, MushafState>(
        builder: (context, state) => Text(
          'صفحة ${ArabicNumberConverter.convert(state.pageNumber)}'
          ' / ${ArabicNumberConverter.convert(MushafEdition.pageCount)}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      actions: [
        BlocBuilder<MushafCubit, MushafState>(
          builder: (context, state) {
            final isTajweed = state.edition == MushafEdition.tajweed;
            return TextButton.icon(
              onPressed: () => context.read<MushafCubit>().toggleEdition(),
              icon: Icon(
                isTajweed ? Icons.palette : Icons.palette_outlined,
                color: isTajweed ? AppColors.accentGoldLight : Colors.white,
              ),
              label: Text(
                isTajweed
                    ? MushafEdition.tajweed.labelAr
                    : MushafEdition.standard.labelAr,
                style: TextStyle(
                  color: isTajweed ? AppColors.accentGoldLight : Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bottom overlay: a page slider plus the Arabic page counter.
class _MushafControlsBar extends StatelessWidget {
  final int pageNumber;
  final ValueChanged<int> onPageChanged;

  const _MushafControlsBar({
    required this.pageNumber,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.primaryEmeraldDark.withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: AppColors.accentGold, width: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              ArabicNumberConverter.convert(pageNumber),
              style: const TextStyle(
                color: AppColors.accentGoldLight,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accentGoldLight,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.accentGoldLight,
                  overlayColor: AppColors.accentGoldLight.withValues(alpha: 0.2),
                  trackHeight: 3,
                ),
                child: Slider(
                  min: 1,
                  max: MushafEdition.pageCount.toDouble(),
                  value: pageNumber.toDouble(),
                  label: ArabicNumberConverter.convert(pageNumber),
                  onChanged: (value) => onPageChanged(value.round()),
                ),
              ),
            ),
            Text(
              ArabicNumberConverter.convert(MushafEdition.pageCount),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafPageImage extends StatelessWidget {
  final MushafEdition edition;
  final int pageNumber;

  const _MushafPageImage({required this.edition, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 4.0,
      child: Center(
        child: Image.asset(
          edition.pageAssetPath(pageNumber),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const _MissingPage(),
        ),
      ),
    );
  }
}

class _MissingPage extends StatelessWidget {
  const _MissingPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'صفحات المصحف غير مضمّنة.\n'
          'شغّل: python3 tools/process_mushaf_pdf.py',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
