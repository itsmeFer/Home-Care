// lib/firebase_messaging_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ========================================
/// HANDLE BACKGROUND MESSAGES
/// Fungsi ini HARUS top-level function
/// ========================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background Message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ BASE URL - GANTI DENGAN URL BACKEND ANDA
  static const String kBaseUrl = 'http://192.168.1.5:8000';

  // ✅ Channel harus sama dengan backend (Laravel) yang kirim channel_id
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDesc =
      'This channel is used for important notifications.';

  // ✅ Icon Android small notification (resource di android/app/src/main/res/drawable/)
  // File: android/app/src/main/res/drawable/ic_stat_notification.png
  static const String _androidSmallIcon = 'ic_stat_notification';

  /// ========================================
  /// INITIALIZE FCM
  /// ========================================
  static Future<void> initialize() async {
    try {
      print('🔥 Initializing Firebase Messaging...');

      // 1️⃣ Request Permission
      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('✅ Permission Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠️ Notification permission denied by user');
        return;
      }

      // 2️⃣ Setup Local Notifications
      await _setupLocalNotifications();

      // 3️⃣ Get FCM Token
      final String? token = await getToken();
      if (token != null && token.length >= 30) {
        print('🔑 FCM Token: ${token.substring(0, 30)}...');
      } else {
        print('🔑 FCM Token: $token');
      }

      // 4️⃣ Foreground messages -> tampilkan local notif
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5️⃣ Background handler (WAJIB top-level) - dipasang sekali di sini
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 6️⃣ Tap notif saat app background -> buka app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 7️⃣ App dibuka dari terminated state
      final RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // 8️⃣ Token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (newToken.length >= 30) {
          print('🔄 FCM Token Refreshed: ${newToken.substring(0, 30)}...');
        } else {
          print('🔄 FCM Token Refreshed: $newToken');
        }
        saveTokenToBackend(newToken);
      });

      print('✅ Firebase Messaging Initialized!');
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
      // biarkan app tetap jalan
    }
  }

  /// ========================================
  /// SETUP LOCAL NOTIFICATIONS
  /// ========================================
  static Future<void> _setupLocalNotifications() async {
    // ✅ PENTING: jangan pakai @mipmap/ic_launcher di sini
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(_androidSmallIcon);

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ✅ Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// ========================================
  /// GET FCM TOKEN
  /// ========================================
  static Future<String?> getToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }

      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// ========================================
  /// GET DEVICE INFO
  /// ========================================
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    String deviceId = 'unknown';
    String deviceModel = 'unknown';
    String osVersion = 'unknown';
    String deviceType = 'android';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release}';
        deviceType = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceModel = iosInfo.model;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceType = 'ios';
      }
    } catch (e) {
      print('⚠️ Error getting device info: $e');
    }

    String appVersion = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (e) {
      print('⚠️ Error getting app version: $e');
    }

    return {
      'device_id': deviceId,
      'device_model': deviceModel,
      'os_version': osVersion,
      'device_type': deviceType,
      'app_version': appVersion,
    };
  }

  /// ========================================
  /// 📱 SAVE FCM TOKEN - UNVERIFIED USER (AFTER REGISTER)
  /// ========================================
  static Future<void> saveTokenToBackendUnverified(String email) async {
    try {
      print('📤 Saving FCM token for unverified user: $email');

      final String? fcmToken = await getToken();
      if (fcmToken == null) {
        print('⚠️ No FCM token available');
        return;
      }

      final Map<String, String> deviceInfo = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse('$kBaseUrl/api/fcm/token/unverified'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'token': fcmToken,
          'device_id': deviceInfo['device_id'],
          'device_type': deviceInfo['device_type'],
          'device_model': deviceInfo['device_model'],
          'os_version': deviceInfo['os_version'],
          'app_version': deviceInfo['app_version'],
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token saved for unverified user');
        final body = jsonDecode(response.body);
        print('Response: $body');
      } else {
        print('❌ Failed to save FCM token: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving FCM token for unverified user: $e');
    }
  }

  /// ========================================
  /// 📱 SAVE FCM TOKEN - AFTER LOGIN (AUTHENTICATED USER)
  /// ========================================
  static Future<bool> saveTokenToBackendAfterLogin() async {
    try {
      print('📤 Saving FCM token after login...');

      final prefs = await SharedPreferences.getInstance();
      final authToken =
          prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

      if (authToken.isEmpty) {
        print('⚠️ No auth token found, cannot save FCM token');
        return false;
      }

      final String? fcmToken = await getToken();
      if (fcmToken == null) {
        print('⚠️ No FCM token available');
        return false;
      }

      final Map<String, String> deviceInfo = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse('$kBaseUrl/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': fcmToken,
          'device_id': deviceInfo['device_id'],
          'device_type': deviceInfo['device_type'],
          'device_model': deviceInfo['device_model'],
          'os_version': deviceInfo['os_version'],
          'app_version': deviceInfo['app_version'],
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token saved to backend successfully');
        final body = jsonDecode(response.body);
        print('Response: $body');
        return true;
      } else {
        print('❌ Failed to save FCM token: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving FCM token after login: $e');
      return false;
    }
  }

  /// ========================================
  /// SAVE FCM TOKEN TO BACKEND (GENERIC)
  /// ========================================
  static Future<void> saveTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken =
          prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

      if (authToken.isEmpty) {
        print('⚠️ No auth token, skipping FCM token save');
        return;
      }

      final Map<String, String> deviceInfo = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse('$kBaseUrl/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          ...deviceInfo,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token saved to backend');
      } else {
        print('❌ Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// ========================================
  /// DELETE FCM TOKEN FROM BACKEND (LOGOUT)
  /// ========================================
  static Future<void> deleteTokenFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken =
          prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

      if (authToken.isEmpty) return;

      final Map<String, String> deviceInfo = await _getDeviceInfo();

      final response = await http.delete(
        Uri.parse('$kBaseUrl/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'device_id': deviceInfo['device_id'],
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token deleted from backend');
      }
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  /// ========================================
  /// HANDLE FOREGROUND MESSAGES
  /// ========================================
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground Message Received!');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    _showLocalNotification(message);
  }

  /// ========================================
  /// SHOW LOCAL NOTIFICATION (ONLY ON FOREGROUND)
  /// ========================================
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: _androidSmallIcon,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// ========================================
  /// HANDLE NOTIFICATION TAP (LOCAL NOTIF)
  /// ========================================
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification Tapped!');
    print('Payload: ${response.payload}');

    if (response.payload == null) return;

    final Map<String, dynamic> data = jsonDecode(response.payload!);
    _handleNavigationFromNotification(data);
  }

  /// ========================================
  /// HANDLE MESSAGE OPENED APP (FCM TAP)
  /// ========================================
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('🚀 App Opened from Notification!');
    print('Data: ${message.data}');

    _handleNavigationFromNotification(message.data);
  }

  /// ========================================
  /// HANDLE NAVIGATION FROM NOTIFICATION
  /// ========================================
  static void _handleNavigationFromNotification(Map<String, dynamic> data) {
    final notificationType = data['type'];

    print('📍 Notification Type: $notificationType');
    print('📦 Data: $data');

    switch (notificationType) {
      case 'email_verified':
        print('🎉 Email verified! Navigate to home');
        break;
      case 'order_created':
        print('📦 Order created! Navigate to order payment');
        break;
      case 'payment_success':
        print('💰 Payment success! Navigate to order detail');
        break;
      default:
        print('📍 Navigate to: ${data['screen'] ?? 'home'}');
    }
  }

  /// ========================================
  /// DELETE TOKEN (LOGOUT - LOCAL)
  /// ========================================
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      print('✅ FCM Token deleted locally');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }
}