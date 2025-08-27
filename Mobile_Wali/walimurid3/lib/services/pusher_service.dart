import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Callback untuk handle navigation
  Function(Map<String, dynamic>)? onNotificationTapCallback;

  Future<void> initialize({
    Function(Map<String, dynamic>)? onNotificationTap,
  }) async {
    onNotificationTapCallback = onNotificationTap;

    // Init local notifications
    await _initializeLocalNotifications();

    // Request permission iOS + Android 13
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Dapatkan FCM token untuk device ini
    String? token = await _messaging.getToken();
    print("📱 Device FCM Token: $token");

    // Listener: notifikasi diterima saat app foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📨 Foreground message: ${message.data}");
      _handleMessage(message);
    });

    // Listener: notifikasi diklik saat app background / terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🎯 Notification tapped (background): ${message.data}");
      if (onNotificationTapCallback != null) {
        onNotificationTapCallback!(message.data);
      }
    });

    // Jika app dibuka dari notifikasi (terminated state)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("🎯 Notification tapped (terminated): ${initialMessage.data}");
      if (onNotificationTapCallback != null) {
        onNotificationTapCallback!(initialMessage.data);
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _handleMessage(RemoteMessage message) {
    String title = message.notification?.title ?? "Notifikasi";
    String body = message.notification?.body ?? "";
    Map<String, dynamic> data = message.data;

    print("🔔 Showing notification: $title - $body");
    _showLocalNotification(title, body, data);
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'absensi_channel',
      'Notifikasi Absensi',
      channelDescription: 'Notifikasi untuk absensi sekolah',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: json.encode(data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = json.decode(response.payload!);
        print("🎯 Notification tapped with data: $data");
        if (onNotificationTapCallback != null) {
          onNotificationTapCallback!(data);
        }
      } catch (e) {
        print("❌ Error parsing payload: $e");
      }
    }
  }
}