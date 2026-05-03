import '../utils/app_config.dart';
import 'dart:async';
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
//  Two notification paths:
//
//  1. TOPIC push  → new blood requirement created
//     Server sends to topic  blood_<type>  (e.g. blood_A_pos).
//     Device subscribes via subscribeToTopic().
//     Subscription retried in background until confirmed.
//
//  2. DIRECT push → donor pledges, requester is notified
//     Server looks up requester's fcmTokens in DB and sends directly.
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
  static const String _channelName = AppConfig.fcmChannelName;
  static const String _channelDesc = AppConfig.fcmChannelDesc;

  bool    _listenersRegistered = false; // permission + listeners done once per login
  String? _subscribedTopic;            // topic currently confirmed on device
  bool    _tokenSavedToBackend = false; // true once backend confirmed token
  Timer?  _retryTimer;                 // background retry timer
  String  _currentBloodType   = '';
  String  _currentUsername    = '';

  // Stored subscription so we can cancel it on logout and avoid stacking
  // duplicate foreground listeners across multiple login/logout cycles.
  StreamSubscription<RemoteMessage>? _onMessageSub;

  /// Register background handler — must be called before runApp().
  static Future<void> setupBackground() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ─────────────────────────────────────────────────────────────
  //  ensureInitialized — call after login AND on app resume.
  //
  //  • Runs permission + listeners once per login session
  //  • Saves FCM token to backend (retried until success)
  //  • Subscribes to blood-type topic (retried until success)
  //  • Starts a background retry timer for transient FIS failures
  // ─────────────────────────────────────────────────────────────
  Future<void> ensureInitialized({required String bloodType, String username = ''}) async {
    _currentBloodType = bloodType;
    _currentUsername  = username;

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
  //  _setupPermissionsAndListeners — runs exactly once per login session.
  //
  //  The previous _onMessageSub is cancelled before a new one is registered,
  //  preventing duplicate foreground notification listeners from stacking up
  //  across multiple login/logout/login cycles on the same device.
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

    // Cancel any existing foreground listener before registering a new one.
    // Without this, each login after logout would add another listener,
    // causing the same notification to be shown multiple times.
    await _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
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
  //
  //  Two filters for requirement notifications:
  //
  //  1. Blood-type mismatch — topic subscriptions can lag (e.g.
  //     after reinstall / blood-type change), so we verify that
  //     the requirement's bloodType actually matches the user's.
  //
  //  2. Creator suppression — FCM topic push cannot exclude the
  //     user who created the requirement server-side, so we drop
  //     it here using the createdBy field the server now sends.
  //
  //  All other notification types (pledge, etc.) pass through.
  // ─────────────────────────────────────────────────────────────
  Future<bool> _shouldShowNotification(RemoteMessage msg) async {
    try {
      final type = msg.data['type'];
      if (type != 'requirement') return true; // always show pledge / other types

      // ── Filter 1: blood-type mismatch ──────────────────────
      final requirementBloodType = msg.data['bloodType'] as String?;
      if (requirementBloodType != null && _currentBloodType.isNotEmpty) {
        if (requirementBloodType != _currentBloodType) {
          debugPrint(
            'FCM: suppressed — requirement needs $requirementBloodType, '
            'user is $_currentBloodType',
          );
          return false;
        }
      }

      // ── Filter 2: creator suppression ──────────────────────
      final createdBy = msg.data['createdBy'] as String?;
      if (createdBy != null && createdBy.isNotEmpty && _currentUsername.isNotEmpty) {
        if (_currentUsername == createdBy) {
          debugPrint(
            'FCM: suppressed — user "$_currentUsername" is the requester',
          );
          return false;
        }
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  unsubscribeAll — call on logout to clean up fully.
  //
  //  Fixes addressed here:
  //  • _currentUsername is now reset so the next user's suppression
  //    filter starts clean (previously it retained the old username).
  //  • _onMessageSub is cancelled so the foreground listener is removed;
  //    the next login re-registers a fresh one via _setupPermissionsAndListeners.
  // ─────────────────────────────────────────────────────────────
  Future<void> unsubscribeAll() async {
    _retryTimer?.cancel();
    _retryTimer = null;

    // Cancel foreground message listener — prevents stale listener from
    // the previous user's session being active during the next user's session.
    await _onMessageSub?.cancel();
    _onMessageSub = null;

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
    _currentUsername     = ''; // ← was missing; caused stale username in
                                //   _shouldShowNotification after user switch
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
