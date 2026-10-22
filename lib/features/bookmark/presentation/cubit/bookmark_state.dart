import 'package:equatable/equatable.dart';
import '../../domain/entities/bookmark.dart';

abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object?> get props => [];
}

class BookmarkInitial extends BookmarkState {
  const BookmarkInitial();
}

class BookmarkLoading extends BookmarkState {
  const BookmarkLoading();
}

class BookmarkLoaded extends BookmarkState {
  final Bookmark? bookmark;

  const BookmarkLoaded({this.bookmark});

  @override
  List<Object?> get props => [bookmark];
}
