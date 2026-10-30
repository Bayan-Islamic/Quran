import 'package:equatable/equatable.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/mushaf_bookmark.dart';

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
  final MushafBookmark? mushafBookmark;

  const BookmarkLoaded({this.bookmark, this.mushafBookmark});

  @override
  List<Object?> get props => [bookmark, mushafBookmark];
}
