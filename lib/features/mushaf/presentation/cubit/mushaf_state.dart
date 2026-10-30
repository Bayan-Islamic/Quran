import 'package:equatable/equatable.dart';

import '../../domain/entities/mushaf_edition.dart';

/// State of the page-by-page Mushaf reader.
abstract class MushafState extends Equatable {
  final MushafEdition edition;
  final int pageNumber;

  const MushafState({required this.edition, required this.pageNumber});

  @override
  List<Object?> get props => [edition, pageNumber];
}

class MushafInitial extends MushafState {
  const MushafInitial({required super.edition, super.pageNumber = 1});
}

class MushafLoaded extends MushafState {
  const MushafLoaded({required super.edition, required super.pageNumber});

  MushafLoaded copyWith({MushafEdition? edition, int? pageNumber}) =>
      MushafLoaded(
        edition: edition ?? this.edition,
        pageNumber: pageNumber ?? this.pageNumber,
      );
}

/// Raised when a page image cannot be found in the bundle.
class MushafUnavailable extends MushafState {
  const MushafUnavailable({required super.edition, super.pageNumber = 1});
}
