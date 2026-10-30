/// A bundled page-by-page Mushaf edition.
///
/// Both editions are aligned page-for-page, so the same [pageNumber] shows the
/// same Qur'anic page and the reader keeps its place when switching editions.
enum MushafEdition {
  /// The plain Uthmani Madani Mushaf (طبعة مجمع الملك فهد).
  standard(
    labelAr: 'المصحف',
    labelEn: 'Standard',
    assetDirectory: 'assets/mushaf/standard',
  ),

  /// The colour-coded Tajweed Mushaf (مصحف التجويد الملون).
  tajweed(
    labelAr: 'التجويد',
    labelEn: 'Tajweed',
    assetDirectory: 'assets/mushaf/tajweed',
  );

  const MushafEdition({
    required this.labelAr,
    required this.labelEn,
    required this.assetDirectory,
  });

  final String labelAr;
  final String labelEn;
  final String assetDirectory;

  /// Number of printed pages in the Madani Mushaf.
  static const int pageCount = 604;

  /// Asset path of the image for a 1-based Qur'an page (1–604).
  String pageAssetPath(int pageNumber) =>
      '$assetDirectory/page_${pageNumber.toString().padLeft(3, '0')}.webp';
}
