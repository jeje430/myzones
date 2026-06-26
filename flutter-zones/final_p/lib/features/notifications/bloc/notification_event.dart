import 'package:equatable/equatable.dart';

import '../models/push_message.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class SyncFcmTokenRequested extends NotificationEvent {
  const SyncFcmTokenRequested();
}

class NotificationReceived extends NotificationEvent {
  const NotificationReceived(this.message);

  final PushMessage message;

  @override
  List<Object?> get props => [message];
}

class NotificationDismissed extends NotificationEvent {
  const NotificationDismissed();
}

class NotificationNavigateRequested extends NotificationEvent {
  const NotificationNavigateRequested(this.target);

  final PushNavigationTarget target;

  @override
  List<Object?> get props => [target];
}
