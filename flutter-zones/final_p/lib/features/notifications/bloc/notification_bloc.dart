import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/notification_repository.dart';
import '../models/push_message.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository.instance,
        super(const NotificationIdle()) {
    on<SyncFcmTokenRequested>(_onSyncToken);
    on<NotificationReceived>(_onReceived);
    on<NotificationDismissed>(_onDismissed);
    on<NotificationNavigateRequested>(_onNavigate);

    _foregroundSub = _repository.foregroundMessages.listen((message) {
      add(NotificationReceived(message));
    });
    _navigationSub = _repository.navigationTargets.listen((target) {
      add(NotificationNavigateRequested(target));
    });
  }

  final NotificationRepository _repository;
  StreamSubscription<PushMessage>? _foregroundSub;
  StreamSubscription<PushNavigationTarget>? _navigationSub;

  Future<void> _onSyncToken(
    SyncFcmTokenRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.registerTokenWithLaravel();
  }

  void _onReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationForegroundBanner(event.message));
  }

  void _onDismissed(
    NotificationDismissed event,
    Emitter<NotificationState> emit,
  ) {
    emit(const NotificationIdle());
  }

  void _onNavigate(
    NotificationNavigateRequested event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationNavigate(event.target));
    emit(const NotificationIdle());
  }

  @override
  Future<void> close() {
    _foregroundSub?.cancel();
    _navigationSub?.cancel();
    return super.close();
  }
}
