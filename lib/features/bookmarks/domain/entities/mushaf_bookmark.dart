import 'package:equatable/equatable.dart';

/// A bookmark placed on a printed Mushaf page (1–604).
///
/// Kept separate from [Bookmark], which tracks the last-read ayah for the
/// surah reader; a Mushaf page bookmark drives the ribbon and the "Continue
/// reading" shortcut inside the page-by-page reader.
class MushafBookmark extends Equatable {
  final int pageNumber;
  final String updatedAt;

  const MushafBookmark({
    required this.pageNumber,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [pageNumber, updatedAt];
}
