import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'app/bloc_observer.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  await PushNotificationService.instance.initialize();

  Bloc.observer = ZonezBlocObserver();

  runApp(const ZonezRoot());
}
