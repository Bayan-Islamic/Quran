import 'package:equatable/equatable.dart';
import '../../domain/entities/ayah_content.dart';

abstract class TafsirState extends Equatable {
  const TafsirState();

  @override
  List<Object?> get props => [];
}

class TafsirInitial extends TafsirState {
  const TafsirInitial();
}

class TafsirLoading extends TafsirState {
  const TafsirLoading();
}

class TafsirLoaded extends TafsirState {
  final AyahContent? content;

  const TafsirLoaded(this.content);

  @override
  List<Object?> get props => [content];
}

class TafsirError extends TafsirState {
  final String message;

  const TafsirError(this.message);

  @override
  List<Object?> get props => [message];
}
