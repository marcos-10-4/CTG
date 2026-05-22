import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_notifier.g.dart';

@riverpod
class FcmNotifier extends _$FcmNotifier {
  @override
  Future<void> build() async {
    if (kIsWeb) return;
    await _init();
  }

  Future<void> _init() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe to socios topic
    await messaging.subscribeToTopic('socios');

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // In a real app: show local notification via flutter_local_notifications
    });
  }

  Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }
}
