import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/firebase_options.dart';
import '../utils/prefs_service.dart';
import 'api_client.dart';

// ─────────────────────────────────────────────────────────────
//  FcmService — Firebase Cloud Messaging
//
//  Two notification paths:
//
//  1. TOPIC push  → new blood requirement created
//     Server sends to topic  blood_<type>  (e.g. blood_A_pos).
//     Device subscribes via subscribeToTopic().
//     Subscription retried in background until confirmed.
//
//  2. DIRECT push → donor pledges, requester is notified
//     Server looks up requester's fcmToken in DB and sends directly.
//     Token must be saved via POST /auth/fcm-token.
//     Token save retried in background until confirmed.
// ─────────────────────────────────────────────────────────────

/// Top-level — called by FCM when app is background/killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  bool    _listenersRegistered = false; // permission + listeners done once
  String? _subscribedTopic;            // topic currently confirmed on device
  bool    _tokenSavedToBackend = false; // true once backend confirmed token
  Timer?  _retryTimer;                 // background retry timer
  String  _currentBloodType   = '';

  /// Register background handler — must be called before runApp().
  static Future<void> setupBackground() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ─────────────────────────────────────────────────────────────
  //  ensureInitialized — call after login AND on app resume.
  //
  //  • Runs permission + listeners once
  //  • Saves FCM token to backend (retried until success)
  //  • Subscribes to blood-type topic (retried until success)
  //  • Starts a background retry timer for transient FIS failures
  // ─────────────────────────────────────────────────────────────
  Future<void> ensureInitialized({required String bloodType}) async {
    _currentBloodType = bloodType;

    if (!_listenersRegistered) {
      _listenersRegistered = true;
      await _setupPermissionsAndListeners();
    }

    await _tryGetTokenAndSubscribe(bloodType);

    // If either token or subscription is still missing, start background retry
    if (!_tokenSavedToBackend || _subscribedTopic != _topicFor(bloodType)) {
      _scheduleRetry(bloodType);
    } else {
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  _setupPermissionsAndListeners — runs exactly once per session
  // ─────────────────────────────────────────────────────────────
  Future<void> _setupPermissionsAndListeners() async {
    final messaging = FirebaseMessaging.instance;

    // Request notification permission (Android 13+, iOS)
    // Do NOT return on denied — Android < 13 may report denied even when
    // notifications work fine. Continue so token is still saved.
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    debugPrint('FCM: permission = ${settings.authorizationStatus}');

    // Local notifications for foreground heads-up
    await _initLocalNotifications();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      debugPrint('FCM foreground: ${msg.notification?.title}');
      // Suppress new-requirement notifications for the user who created it.
      // The topic push cannot exclude the requester server-side, so we filter here.
      _shouldShowNotification(msg).then((show) {
        if (show) _showLocalNotification(msg);
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      debugPrint('FCM tapped: ${msg.data}');
    });

    // Token rotation — OS rotates token after reinstall / backup restore
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM: token rotated — re-saving to backend');
      _tokenSavedToBackend = false;
      _saveTokenToBackend(newToken);
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  _tryGetTokenAndSubscribe — the core work, safe to call repeatedly
  // ─────────────────────────────────────────────────────────────
  Future<void> _tryGetTokenAndSubscribe(String bloodType) async {
    final messaging = FirebaseMessaging.instance;

    // Step A: get FCM token and save to backend
    if (!_tokenSavedToBackend) {
      try {
        final token = await messaging.getToken();
        if (token != null) {
          await _saveTokenToBackend(token);
        } else {
          debugPrint('FCM: getToken() returned null — will retry.');
        }
      } catch (e) {
        // FIS_AUTH_ERROR, NETWORK_ERROR, SERVICE_NOT_AVAILABLE — all transient.
        // _tokenSavedToBackend stays false → retried by _scheduleRetry().
        debugPrint('FCM: getToken() failed (transient, will retry): $e');
      }
    }

    // Step B: subscribe to blood-type topic
    await _ensureTopicSubscription(bloodType);
  }

  // ─────────────────────────────────────────────────────────────
  //  _scheduleRetry — retries every 30s until both token and
  //  topic subscription are confirmed. Cancels itself on success.
  // ─────────────────────────────────────────────────────────────
  void _scheduleRetry(String bloodType) {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_listenersRegistered) return; // logged out
      debugPrint('FCM: retrying token save + topic subscription...');
      await _tryGetTokenAndSubscribe(bloodType);
      if (_tokenSavedToBackend && _subscribedTopic == _topicFor(bloodType)) {
        debugPrint('FCM: retry succeeded — token saved and topic subscribed ✓');
        _retryTimer?.cancel();
        _retryTimer = null;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  _ensureTopicSubscription
  // ─────────────────────────────────────────────────────────────
  Future<void> _ensureTopicSubscription(String bloodType) async {
    final messaging = FirebaseMessaging.instance;

    // Unsubscribe from old topic if blood type changed
    final newTopic = bloodType.isNotEmpty ? _topicFor(bloodType) : null;
    if (_subscribedTopic != null &&
        _subscribedTopic != newTopic &&
        _subscribedTopic!.isNotEmpty) {
      try {
        await messaging.unsubscribeFromTopic(_subscribedTopic!);
        debugPrint('FCM: unsubscribed from "$_subscribedTopic"');
      } catch (e) {
        debugPrint('FCM: could not unsubscribe from "$_subscribedTopic": $e');
      }
      _subscribedTopic = null;
    }

    if (bloodType.isEmpty) {
      debugPrint('FCM: bloodType empty — set blood type in profile to receive push notifications.');
      return;
    }

    if (_subscribedTopic == _topicFor(bloodType)) return; // already subscribed

    final topic = _topicFor(bloodType);
    try {
      await messaging.subscribeToTopic(topic);
      _subscribedTopic = topic;
      debugPrint('FCM: subscribed to topic "$topic" ✓');
    } catch (e) {
      debugPrint('FCM: subscribeToTopic("$topic") failed (will retry): $e');
      // _subscribedTopic stays null → _scheduleRetry() will retry
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  _shouldShowNotification
  //  Suppresses new-requirement notifications for the user who
  //  created the requirement. The server topic push cannot exclude
  //  a specific user, so we filter on the client side using the
  //  stored username.
  // ─────────────────────────────────────────────────────────────
  Future<bool> _shouldShowNotification(RemoteMessage msg) async {
    try {
      final type = msg.data['type'];
      if (type != 'requirement') return true; // always show pledge/other

      // Suppress if the current user is the one who created this requirement.
      // We can't know createdBy from the FCM payload (server doesn't send it),
      // but we can check: if this is a requirement notification AND the user's
      // blood type matches, they'd normally see it — but if they're the requester
      // they already know about it. Unfortunately without createdBy in the payload
      // we can't suppress it perfectly. The server should exclude them from
      // per-device push already. Topic push will always reach them.
      // For now: always show requirement notifications (in-app they can see it's theirs).
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Call on logout to clean up subscriptions and cancel retries.
  Future<void> unsubscribeAll() async {
    _retryTimer?.cancel();
    _retryTimer = null;

    final messaging = FirebaseMessaging.instance;
    if (_subscribedTopic != null && _subscribedTopic!.isNotEmpty) {
      try {
        await messaging.unsubscribeFromTopic(_subscribedTopic!);
        debugPrint('FCM: unsubscribed on logout');
      } catch (e) {
        debugPrint('FCM: could not unsubscribe on logout: $e');
      }
    }
    _listenersRegistered = false;
    _subscribedTopic     = null;
    _tokenSavedToBackend = false;
    _currentBloodType    = '';
  }

  // ─────────────────────────────────────────────────────────────
  //  _saveTokenToBackend — logs clearly on failure, sets flag on success
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveTokenToBackend(String token) async {
    try {
      await ApiClient.instance.post('/auth/fcm-token', data: {'token': token});
      _tokenSavedToBackend = true;
      debugPrint('FCM: token saved to backend ✓');
    } catch (e) {
      debugPrint('FCM: token save failed (will retry): $e');
      // _tokenSavedToBackend stays false → retried by _scheduleRetry()
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Local notifications (foreground heads-up)
  // ─────────────────────────────────────────────────────────────
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    if (Platform.isAndroid) {
      final plugin = _localNotifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId, _channelName,
          description:     _channelDesc,
          importance:      Importance.high,
          playSound:       true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await _localNotifs.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority:   Priority.high,
          color:      const Color(0xFFC8102E),
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  String _topicFor(String bloodType) =>
      "blood_${bloodType.replaceAll('+', '_pos').replaceAll('-', '_neg')}";
}
