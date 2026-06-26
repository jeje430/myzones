import 'package:equatable/equatable.dart';

class PushMessage extends Equatable {
  const PushMessage({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;
  final Map<String, String> data;

  @override
  List<Object?> get props => [title, body, data];
}

class PushNavigationTarget extends Equatable {
  const PushNavigationTarget({
    required this.tournamentId,
    required this.tournamentTitle,
  });

  final String tournamentId;
  final String tournamentTitle;

  @override
  List<Object?> get props => [tournamentId, tournamentTitle];
}
