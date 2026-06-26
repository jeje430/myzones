import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_guard.dart';

Future<void> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseGuard.ready = true;

    if (kDebugMode) {
      return;
    }

    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    FirebaseGuard.ready = false;
    debugPrint('Firebase bootstrap skipped: $e');
  }
}
