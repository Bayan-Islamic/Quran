import 'package:equatable/equatable.dart';
import '../../domain/entities/ayah.dart';

abstract class QuranReaderState extends Equatable {
  final double fontSize;

  const QuranReaderState({this.fontSize = 24.0});

  @override
  List<Object?> get props => [fontSize];
}

class QuranReaderInitial extends QuranReaderState {
  const QuranReaderInitial({super.fontSize});
}

class QuranReaderLoading extends QuranReaderState {
  const QuranReaderLoading({super.fontSize});
}

class QuranReaderLoaded extends QuranReaderState {
  final List<Ayah> ayahs;

  const QuranReaderLoaded({
    required this.ayahs,
    super.fontSize = 24.0,
  });

  QuranReaderLoaded copyWith({
    List<Ayah>? ayahs,
    double? fontSize,
  }) {
    return QuranReaderLoaded(
      ayahs: ayahs ?? this.ayahs,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  List<Object?> get props => [ayahs, fontSize];
}

class QuranReaderError extends QuranReaderState {
  final String message;

  const QuranReaderError(this.message, {super.fontSize});

  @override
  List<Object?> get props => [message, fontSize];
}
