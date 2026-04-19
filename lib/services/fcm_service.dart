import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/firebase_options.dart';
import 'api_client.dart';

// ─────────────────────────────────────────────────────────────
//  FcmService — Firebase Cloud Messaging
//
//  Subscribes to topics:
//    'all'            → every user
//    'blood_<type>'   → e.g. blood_A_pos, blood_O_neg
//
//  Shows a heads-up local notification when the app is in the
//  foreground. Background/killed messages are shown by the OS.
// ─────────────────────────────────────────────────────────────

/// Must be top-level — called by FCM when app is background/killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('FCM background: ${message.notification?.title}');
}

class FcmService {
  static final FcmService _instance = FcmService._();
  FcmService._();
  factory FcmService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const String _channelId   = 'bloodconnect_alerts';
  static const String _channelName = 'Blood Alerts';
  static const String _channelDesc = 'Notifications for blood donation requests';

  bool    _initialized       = false;
  String? _currentBloodType;

  /// Register background handler — call before runApp() in main().
  static Future<void> setupBackground() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Call after login with the user's blood type.
  Future<void> init({required String bloodType}) async {
    if (_initialized) {
      if (_currentBloodType != bloodType) {
        await _resubscribe(bloodType);
      }
      // Always re-save the token on every init call so the backend stays
      // up-to-date even if the endpoint was unavailable on a previous call.
      final existingToken = await FirebaseMessaging.instance.getToken();
      if (existingToken != null) _saveTokenToBackend(existingToken);
      return;
    }
    _initialized      = true;
    _currentBloodType = bloodType;

    final messaging = FirebaseMessaging.instance;

    // ── Request permission ────────────────────────────────────
    final settings = await messaging.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: notification permission denied');
      return;
    }

    // ── Get FCM token ─────────────────────────────────────────
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
    if (token != null) _saveTokenToBackend(token);
    messaging.onTokenRefresh.listen(_saveTokenToBackend);

    // ── Subscribe to blood type topic only ──────────────────
    // We only subscribe to the user's blood type topic.
    // The server sends to blood type topics only (not 'all'),
    // so one device = one notification per requirement.
    if (bloodType.isNotEmpty) {
      await messaging.subscribeToTopic(_topic(bloodType));
      debugPrint('FCM: subscribed to topic: ${_topic(bloodType)}');
    }

    // ── Local notifications setup (foreground) ────────────────
    await _initLocalNotifications();

    // ── Foreground messages ───────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // ── Tap on background notification ────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM tapped from background: ${message.data}');
    });
  }

  Future<void> _resubscribe(String newBloodType) async {
    final messaging = FirebaseMessaging.instance;
    if (_currentBloodType != null && _currentBloodType!.isNotEmpty) {
      await messaging.unsubscribeFromTopic(_topic(_currentBloodType!));
    }
    if (newBloodType.isNotEmpty) {
      await messaging.subscribeToTopic(_topic(newBloodType));
    }
    _currentBloodType = newBloodType;
  }

  Future<void> unsubscribeAll() async {
    final messaging = FirebaseMessaging.instance;
    if (_currentBloodType != null && _currentBloodType!.isNotEmpty) {
      await messaging.unsubscribeFromTopic(_topic(_currentBloodType!));
    }
    _initialized      = false;
    _currentBloodType = null;
  }

  Future<void> _initLocalNotifications() async {
    // Android init settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission:  false,
      requestBadgePermission:  false,
      requestSoundPermission:  false,
    );

    await _localNotifs.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
    );

    // Create high-importance Android notification channel
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifs
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description:     _channelDesc,
          importance:      Importance.high,
          playSound:       true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance:         Importance.high,
      priority:           Priority.high,
      color:              const Color(0xFFC8102E),
      icon:               '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifs.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS:     iosDetails,
      ),
    );
  }

  String _topic(String bloodType) =>
      'blood_${bloodType.replaceAll('+', '_pos').replaceAll('-', '_neg')}';

  Future<void> _saveTokenToBackend(String token) async {
    try {
      await ApiClient.instance.post('/auth/fcm-token', data: {'token': token});
    } catch (_) {
      // Non-critical
    }
  }
}
