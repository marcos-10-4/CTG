import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:ctg_app/core/router/app_router.dart';
import 'package:ctg_app/core/theme/app_theme.dart';
import 'package:ctg_app/features/notifications/application/notifications_notifier.dart';
import 'package:ctg_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale setup — required before any DateFormat('...', 'es') calls
  await initializeDateFormatting('es');
  timeago.setLocaleMessages('es', timeago.EsMessages());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect to local emulators in debug and profile builds (not release)
  // Uncomment to use local emulators during development:
  // if (kDebugMode) await _connectEmulators();

  // Crashlytics — not supported on web
  if (!kIsWeb) {
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(
    const ProviderScope(
      child: CtgApp(),
    ),
  );
}

// ignore: unused_element
Future<void> _connectEmulators() async {
  // Physical Android devices can't reach localhost — use the PC's LAN IP.
  // Web and desktop on the same machine use localhost.
  const host =
      kIsWeb ? 'localhost' : String.fromEnvironment('EMULATOR_HOST', defaultValue: '192.168.1.49');

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

class CtgApp extends ConsumerWidget {
  const CtgApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Init FCM (no-op on web)
    if (!kIsWeb) ref.watch(fcmNotifierProvider);

    return MaterialApp.router(
      title: 'CTG — Club de Tenis Gondomar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
