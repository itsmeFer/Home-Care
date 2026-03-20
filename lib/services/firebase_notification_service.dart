import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// BASE URL API
const String kBaseUrl = 'http://147.93.81.243/api';

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
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('✅ Android notification channel created');
    }
  }

  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        final shortToken = _fcmToken!.length > 20
            ? _fcmToken!.substring(0, 20)
            : _fcmToken!;
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
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      debugPrint(
        '🔑 Auth token available for FCM sync: ${authToken != null && authToken.isNotEmpty}',
      );

      if (authToken == null || authToken.isEmpty) {
        debugPrint('⚠️ User belum login, skip kirim FCM token');
        return;
      }

      String? token = _fcmToken;
      token ??= await _firebaseMessaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ FCM token kosong, tidak bisa dikirim ke backend');
        return;
      }

      final deviceId = token.length >= 32 ? token.substring(0, 32) : token;

      final response = await http.post(
        Uri.parse('$kBaseUrl/fcm/token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'device_id': deviceId,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM token sent to backend successfully');
        debugPrint('Response: ${response.body}');
      } else {
        debugPrint('⚠️ Failed to send FCM token: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
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
    final notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  void _setupMessageOpenedHandler() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('🔔 App opened from terminated state via notification');
        _handleNotificationTap(json.encode(message.data));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔔 App opened from background via notification');
      _handleNotificationTap(json.encode(message.data));
    });
  }

  void _handleNotificationTap(String payload) {
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type']?.toString() ?? '';
      final screen = data['screen']?.toString() ?? '';

      debugPrint('🔔 Notification tapped - Type: $type, Screen: $screen');
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token refreshed');
      _fcmToken = newToken;
      await syncTokenToBackend();
    });
  }

  String? get fcmToken => _fcmToken;

  Future<void> deactivateToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        debugPrint('⚠️ No auth token, skipping token deactivation');
        return;
      }

      final deviceId = (_fcmToken != null && _fcmToken!.isNotEmpty)
          ? (_fcmToken!.length >= 32
              ? _fcmToken!.substring(0, 32)
              : _fcmToken!)
          : '';

      final response = await http.post(
        Uri.parse('$kBaseUrl/fcm/token/deactivate'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token deactivated successfully');
        debugPrint('Response: ${response.body}');
      } else {
        debugPrint('⚠️ Failed to deactivate FCM token: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
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