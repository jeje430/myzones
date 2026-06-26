import 'package:equatable/equatable.dart';

import '../models/push_message.dart';

sealed class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationIdle extends NotificationState {
  const NotificationIdle();
}

class NotificationForegroundBanner extends NotificationState {
  const NotificationForegroundBanner(this.message);

  final PushMessage message;

  @override
  List<Object?> get props => [message];
}

class NotificationNavigate extends NotificationState {
  const NotificationNavigate(this.target);

  final PushNavigationTarget target;

  @override
  List<Object?> get props => [target];
}
