import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Callback untuk handle navigation
  Function(Map<String, dynamic>)? onNotificationTapCallback;

  Future<void> initialize({
    required String userId,
    Function(Map<String, dynamic>)? onNotificationTap,
  }) async {
    onNotificationTapCallback = onNotificationTap;
    
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize Pusher
    await pusher.init(
      apiKey: "your-app-key", // Ganti dengan key dari dashboard Pusher
      cluster: "ap-southeast-1", // Ganti dengan cluster Anda
      onConnectionStateChange: onConnectionStateChange,
      onError: onError,
      onSubscriptionSucceeded: onSubscriptionSucceeded,
      onEvent: onEvent,
    );

    // Connect to Pusher
    await pusher.connect();

    // Subscribe to user-specific channel (untuk wali murid tertentu)
    await pusher.subscribe(channelName: "wali-$userId");
    
    // Subscribe to general channel (untuk broadcast ke semua wali)
    await pusher.subscribe(channelName: "absensi-broadcast");
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

    // Request permission untuk Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("Pusher Connection: $currentState");
  }

  void onError(String message, int? code, dynamic e) {
    print("Pusher Error: $message");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("Subscribed to: $channelName");
  }

  void onEvent(PusherEvent event) {
    print("Event: ${event.eventName} on ${event.channelName}");
    print("Data: ${event.data}");
    
    // Handle different types of notifications
    switch (event.eventName) {
      case "absensi-notification":
        _handleAbsensiNotification(event.data);
        break;
      case "pengumuman":
        _handlePengumumanNotification(event.data);
        break;
      case "reminder":
        _handleReminderNotification(event.data);
        break;
      default:
        _handleGeneralNotification(event.data);
        break;
    }
  }

  void _handleAbsensiNotification(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String title = notificationData['title'] ?? 'Notifikasi Absensi';
      String message = notificationData['message'] ?? '';
      String nisAnak = notificationData['nis_anak'] ?? '';
      String status = notificationData['status'] ?? '';
      String waktu = notificationData['waktu'] ?? '';

      Map<String, dynamic> extraData = {
        'type': 'absensi',
        'nis_anak': nisAnak,
        'status': status,
        'waktu': waktu,
        'redirect': 'dashboard' // Redirect ke dashboard setelah tap
      };

      _showLocalNotification(title, message, extraData, 'absensi');
    } catch (e) {
      print("Error parsing absensi notification: $e");
    }
  }

  void _handlePengumumanNotification(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String title = notificationData['title'] ?? 'Pengumuman Sekolah';
      String message = notificationData['message'] ?? '';
      String pengumumanId = notificationData['pengumuman_id'] ?? '';

      Map<String, dynamic> extraData = {
        'type': 'pengumuman',
        'pengumuman_id': pengumumanId,
        'redirect': 'pengumuman'
      };

      _showLocalNotification(title, message, extraData, 'pengumuman');
    } catch (e) {
      print("Error parsing pengumuman notification: $e");
    }
  }

  void _handleReminderNotification(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String title = notificationData['title'] ?? 'Pengingat';
      String message = notificationData['message'] ?? '';

      Map<String, dynamic> extraData = {
        'type': 'reminder',
        'redirect': 'dashboard'
      };

      _showLocalNotification(title, message, extraData, 'reminder');
    } catch (e) {
      print("Error parsing reminder notification: $e");
    }
  }

  void _handleGeneralNotification(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String title = notificationData['title'] ?? 'Notifikasi';
      String message = notificationData['message'] ?? '';

      Map<String, dynamic> extraData = {
        'type': 'general',
        'redirect': 'dashboard'
      };

      _showLocalNotification(title, message, extraData, 'general');
    } catch (e) {
      print("Error parsing general notification: $e");
    }
  }

  Future<void> _showLocalNotification(
    String title, 
    String body, 
    Map<String, dynamic> data,
    String type
  ) async {
    
    // Different notification channels for different types
    String channelId = 'absensi_$type';
    String channelName = 'Notifikasi ${type.toUpperCase()}';
    String channelDescription = 'Notifikasi untuk $type';

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      sound: const RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const DarwinNotificationDetails iosNotificationDetails = 
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
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
        print("Notification tapped with data: $data");
        
        // Call the callback function if provided
        if (onNotificationTapCallback != null) {
          onNotificationTapCallback!(data);
        }
      } catch (e) {
        print("Error parsing notification payload: $e");
      }
    }
  }

  // Method untuk subscribe ke channel baru (misalnya setelah login)
  Future<void> subscribeToUserChannel(String userId) async {
    await pusher.subscribe(channelName: "wali-$userId");
  }

  // Method untuk unsubscribe dari channel (misalnya setelah logout)
  Future<void> unsubscribeFromUserChannel(String userId) async {
    await pusher.unsubscribe(channelName: "wali-$userId");
  }

  // Method untuk disconnect dari Pusher
  Future<void> disconnect() async {
    await pusher.disconnect();
  }

  // Method untuk reconnect
  Future<void> reconnect() async {
    await pusher.connect();
  }
}