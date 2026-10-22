import 'package:equatable/equatable.dart';
import '../../../quran_reader/domain/entities/ayah.dart';
import '../../../surah_index/domain/entities/surah.dart';

class SearchResult extends Equatable {
  final Ayah ayah;
  final Surah surah;

  const SearchResult({
    required this.ayah,
    required this.surah,
  });

  @override
  List<Object?> get props => [ayah, surah];
}
