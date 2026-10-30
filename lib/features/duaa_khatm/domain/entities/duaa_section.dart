import 'package:equatable/equatable.dart';

/// A section of the Du'aa Khatm al-Qur'an (the supplication recited on
/// completing the Qur'an), with its Arabic text and optional source note.
class DuaaSection extends Equatable {
  final String titleAr;
  final String textAr;
  final String? sourceAr;

  const DuaaSection({
    required this.titleAr,
    required this.textAr,
    this.sourceAr,
  });

  @override
  List<Object?> get props => [titleAr, textAr, sourceAr];
}
