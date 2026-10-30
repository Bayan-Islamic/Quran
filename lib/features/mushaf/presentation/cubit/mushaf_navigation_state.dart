import 'package:equatable/equatable.dart';
import '../../../surah_index/domain/entities/surah.dart';
import '../../domain/entities/juz_info.dart';

abstract class MushafNavigationState extends Equatable {
  const MushafNavigationState();

  @override
  List<Object?> get props => [];
}

class MushafNavigationInitial extends MushafNavigationState {
  const MushafNavigationInitial();
}

class MushafNavigationLoading extends MushafNavigationState {
  const MushafNavigationLoading();
}

class MushafNavigationLoaded extends MushafNavigationState {
  final List<Surah> surahs;
  final List<JuzInfo> juzList;

  const MushafNavigationLoaded({required this.surahs, required this.juzList});

  @override
  List<Object?> get props => [surahs, juzList];
}

class MushafNavigationError extends MushafNavigationState {
  final String message;

  const MushafNavigationError(this.message);

  @override
  List<Object?> get props => [message];
}
