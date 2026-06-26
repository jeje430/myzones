import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../core/firebase/firebase_guard.dart';

class ZonezBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (FirebaseGuard.ready) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
    }
  }
}
