import 'package:equatable/equatable.dart';
import '../../domain/entities/surah.dart';

abstract class SurahIndexState extends Equatable {
  const SurahIndexState();

  @override
  List<Object?> get props => [];
}

class SurahIndexInitial extends SurahIndexState {}

class SurahIndexLoading extends SurahIndexState {}

class SurahIndexLoaded extends SurahIndexState {
  final List<Surah> surahs;
  final String searchQuery;

  const SurahIndexLoaded({
    required this.surahs,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [surahs, searchQuery];
}

class SurahIndexError extends SurahIndexState {
  final String message;

  const SurahIndexError(this.message);

  @override
  List<Object?> get props => [message];
}
