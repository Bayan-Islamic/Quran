import 'package:equatable/equatable.dart';
import '../../domain/entities/ayah.dart';

abstract class QuranReaderState extends Equatable {
  final double fontSize;

  /// Whether the reader shows the colour-coded Tajweed edition.
  final bool tajweedMode;

  const QuranReaderState({this.fontSize = 24.0, this.tajweedMode = false});

  @override
  List<Object?> get props => [fontSize, tajweedMode];
}

class QuranReaderInitial extends QuranReaderState {
  const QuranReaderInitial({super.fontSize, super.tajweedMode});
}

class QuranReaderLoading extends QuranReaderState {
  const QuranReaderLoading({super.fontSize, super.tajweedMode});
}

class QuranReaderLoaded extends QuranReaderState {
  final List<Ayah> ayahs;

  const QuranReaderLoaded({
    required this.ayahs,
    super.fontSize = 24.0,
    super.tajweedMode = false,
  });

  QuranReaderLoaded copyWith({
    List<Ayah>? ayahs,
    double? fontSize,
    bool? tajweedMode,
  }) {
    return QuranReaderLoaded(
      ayahs: ayahs ?? this.ayahs,
      fontSize: fontSize ?? this.fontSize,
      tajweedMode: tajweedMode ?? this.tajweedMode,
    );
  }

  @override
  List<Object?> get props => [ayahs, fontSize, tajweedMode];
}

class QuranReaderError extends QuranReaderState {
  final String message;

  const QuranReaderError(this.message, {super.fontSize, super.tajweedMode});

  @override
  List<Object?> get props => [message, fontSize, tajweedMode];
}
