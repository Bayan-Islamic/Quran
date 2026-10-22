import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository searchRepository;

  SearchCubit({required this.searchRepository})
      : super(const SearchInitial());

  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());
    try {
      final results = await searchRepository.searchAyahs(cleanQuery);
      emit(SearchLoaded(results: results, query: cleanQuery));
    } catch (e) {
      emit(SearchError('حدث خطأ أثناء البحث: ${e.toString()}'));
    }
  }

  void clearSearch() {
    emit(const SearchInitial());
  }
}
