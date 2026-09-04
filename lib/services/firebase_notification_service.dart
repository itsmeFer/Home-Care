import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [BACKGROUND] Message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() => _instance;

  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Firebase Notification Service already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing Firebase Notification Service...');

      await _requestPermission();
      await _setupLocalNotifications();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      await _getFCMToken();
      _setupForegroundHandler();
      _setupMessageOpenedHandler();
      _setupTokenRefreshListener();

      _isInitialized = true;
      debugPrint('✅ Firebase Notification Service initialized successfully!');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Notification: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('✅ Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional permission');
    } else {
      debugPrint('❌ User declined or has not accepted permission');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint('✅ Android notification channel created');
    }
  }

  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        final shortToken =
            _fcmToken!.length > 20 ? _fcmToken!.substring(0, 20) : _fcmToken!;
        debugPrint('✅ FCM Token: $shortToken...');
      } else {
        debugPrint('❌ Failed to get FCM token');
      }

      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> syncTokenToBackend() async {
    try {
      String? token = _fcmToken;
      token ??= await _firebaseMessaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ FCM token kosong, tidak bisa dikirim ke backend');
        return;
      }

      final deviceId = token.length >= 32 ? token.substring(0, 32) : token;
      final deviceType =
          kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios');

      await ApiClient.post(
        ApiConstants.fcmToken,
        body: {
          'token': token,
          'device_id': deviceId,
          'device_type': deviceType,
        },
      );
      debugPrint('✅ FCM token sent to backend successfully');
    } catch (e) {
      debugPrint('❌ Error sending FCM token to backend: $e');
    }
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FOREGROUND] Message received: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'homecare_high_importance_channel',
      'Home Care Notifications',
      channelDescription: 'Pemberitahuan orderan dan chat Home Care',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notifikasi Baru',
      message.notification?.body ?? '',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _setupMessageOpenedHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 App opened from notification: ${message.messageId}');
      debugPrint('Data: ${message.data}');
      _handleNotificationNavigation(message.data);
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint('🧭 Navigating based on notification payload: $data');
  }

  void _handleNotificationTap(String payload) {
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      _handleNotificationNavigation(data);
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      syncTokenToBackend();
    });
  }

  String? get fcmToken => _fcmToken;

  Future<void> deactivateToken() async {
    try {
      final deviceId =
          (_fcmToken != null && _fcmToken!.isNotEmpty)
              ? (_fcmToken!.length >= 32
                  ? _fcmToken!.substring(0, 32)
                  : _fcmToken!)
              : '';

      await ApiClient.post(
        ApiConstants.fcmDeactivateToken,
        body: {'device_id': deviceId},
      );
      debugPrint('✅ FCM token deactivated successfully');
    } catch (e) {
      debugPrint('❌ Error deactivating FCM token: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}
