import 'package:equatable/equatable.dart';

/// A juz' (one of the thirty equal divisions of the Qur'an) with the printed
/// Mushaf page on which it begins.
class JuzInfo extends Equatable {
  final int number;
  final int startPage;

  const JuzInfo({required this.number, required this.startPage});

  @override
  List<Object?> get props => [number, startPage];
}
