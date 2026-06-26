import 'dart:async';

import '../providers/app_state_provider.dart';

/// Keeps Flutter reservations in sync with Laravel while the user is in the app.
class LiveBookingSyncService {
  LiveBookingSyncService._();
  static final LiveBookingSyncService instance = LiveBookingSyncService._();

  static const syncInterval = Duration(seconds: 5);

  Timer? _timer;
  AppStateProvider? _appState;
  bool _busy = false;

  void start(AppStateProvider appState) {
    _appState = appState;
    _timer?.cancel();
    _timer = Timer.periodic(syncInterval, (_) => syncNow());
    syncNow();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _appState = null;
    _busy = false;
  }

  Future<void> syncNow() async {
    final appState = _appState;
    if (appState == null || _busy) return;

    _busy = true;
    try {
      await appState.syncBookingsFromApi();
    } catch (_) {
      // Offline — keep cached state.
    } finally {
      _busy = false;
    }
  }
}
