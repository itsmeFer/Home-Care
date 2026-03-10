import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ✅ BASE URL API
const String kBaseUrl = 'http://192.168.1.6:8000/api';

/// ✅ BACKGROUND MESSAGE HANDLER (WAJIB DI TOP-LEVEL)
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

  /// ✅ INITIALIZE FIREBASE MESSAGING
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Firebase Notification Service already initialized');
      return;
    }

    try {
      debugPrint('🔧 Initializing Firebase Notification Service...');

      // 1️⃣ REQUEST PERMISSION
      await _requestPermission();

      // 2️⃣ SETUP LOCAL NOTIFICATIONS
      await _setupLocalNotifications();

      // 3️⃣ SETUP BACKGROUND HANDLER
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 4️⃣ GET FCM TOKEN
      await _getFCMToken();

      // 5️⃣ SETUP FOREGROUND HANDLER
      _setupForegroundHandler();

      // 6️⃣ SETUP MESSAGE OPENED HANDLER
      _setupMessageOpenedHandler();

      // 7️⃣ TOKEN REFRESH LISTENER
      _setupTokenRefreshListener();

      _isInitialized = true;
      debugPrint('✅ Firebase Notification Service initialized successfully!');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Notification: $e');
    }
  }

  /// ✅ REQUEST NOTIFICATION PERMISSION
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

  /// ✅ SETUP LOCAL NOTIFICATIONS (ANDROID CHANNEL)
  Future<void> _setupLocalNotifications() async {
    // ✅ ANDROID SETTINGS
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    // ✅ IOS SETTINGS
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

    // ✅ CREATE ANDROID NOTIFICATION CHANNEL (HIGH PRIORITY)
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel', // ✅ SAMA DENGAN BACKEND
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

  /// ✅ GET FCM TOKEN
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        debugPrint('✅ FCM Token: ${_fcmToken!.substring(0, 20)}...');
        
        // ✅ AUTO-SEND TOKEN TO BACKEND
        await _sendTokenToBackend(_fcmToken!);
      } else {
        debugPrint('❌ Failed to get FCM token');
      }

      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty) {
      debugPrint('⚠️ User belum login, skip kirim FCM token');
      return;
    }

    final response = await http.post(
      Uri.parse('$kBaseUrl/fcm/token'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token,
        'device_id': token.substring(0, 32),
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

  /// ✅ SETUP FOREGROUND HANDLER (APP TERBUKA)
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FOREGROUND] Message received: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // ✅ SHOW LOCAL NOTIFICATION
      _showLocalNotification(message);
    });
  }

  /// ✅ SHOW LOCAL NOTIFICATION
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
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
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  /// ✅ SETUP MESSAGE OPENED HANDLER (NOTIF DI-TAP)
  void _setupMessageOpenedHandler() {
    // ✅ HANDLE NOTIFICATION TAP DARI TERMINATED STATE
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('🔔 App opened from terminated state via notification');
        _handleNotificationTap(json.encode(message.data));
      }
    });

    // ✅ HANDLE NOTIFICATION TAP DARI BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔔 App opened from background via notification');
      _handleNotificationTap(json.encode(message.data));
    });
  }

  /// ✅ HANDLE NOTIFICATION TAP (NAVIGATION)
  void _handleNotificationTap(String payload) {
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type']?.toString() ?? '';
      final screen = data['screen']?.toString() ?? '';

      debugPrint('🔔 Notification tapped - Type: $type, Screen: $screen');

      // ✅ NAVIGATE BASED ON TYPE
      // TODO: Implement navigation logic
      // Example:
      // if (type == 'new_order') {
      //   navigatorKey.currentState?.pushNamed('/order-detail', arguments: data);
      // }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// ✅ SETUP TOKEN REFRESH LISTENER
  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed');
      _fcmToken = newToken;
      _sendTokenToBackend(newToken);
    });
  }

  /// ✅ GET CURRENT FCM TOKEN
  String? get fcmToken => _fcmToken;

  /// ✅ DEACTIVATE TOKEN (LOGOUT)
  Future<void> deactivateToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty) {
      debugPrint('⚠️ No auth token, skipping token deactivation');
      return;
    }

    final response = await http.post(
      Uri.parse('$kBaseUrl/fcm/token/deactivate'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_id': _fcmToken?.substring(0, 32) ?? '',
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

  /// ✅ DELETE TOKEN (LOGOUT)
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