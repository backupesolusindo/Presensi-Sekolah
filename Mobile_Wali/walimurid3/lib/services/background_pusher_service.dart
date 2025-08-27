import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundPusherService {
  static final BackgroundPusherService _instance = BackgroundPusherService._internal();
  factory BackgroundPusherService() => _instance;
  BackgroundPusherService._internal();

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Initialize background service dengan Pusher
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create notification channel untuk background service
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'background_pusher_channel',
      'Background Pusher Service',
      description: 'Service untuk menerima notifikasi real-time Pusher',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'background_pusher_channel',
        initialNotificationTitle: 'E-Presensi Service',
        initialNotificationContent: 'Menerima notifikasi absensi real-time',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize WorkManager untuk reconnect otomatis
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Register periodic task untuk maintain connection
    await Workmanager().registerPeriodicTask(
      "maintainPusherConnection",
      "checkAndReconnectPusher",
      frequency: const Duration(minutes: 15), // Check setiap 15 menit
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    // Initialize Pusher di background
    await _initializePusherInBackground();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      _disconnectPusher();
      service.stopSelf();
    });

    // Listen untuk update user phone dari main app
    service.on('updateUserPhone').listen((event) async {
      if (event != null && event['userPhone'] != null) {
        await _updatePusherChannel(event['userPhone']);
      }
    });

    // Periodic check untuk connection health
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkPusherConnection();
    });

    print("Background Pusher Service started");
  }

  static PusherChannelsFlutter? _backgroundPusher;
  static String? _currentUserPhone;
  static String? _currentChannel;

  static Future<void> _initializePusherInBackground() async {
    try {
      // Baca user phone dari SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userPhone = prefs.getString('background_user_phone');
      
      if (userPhone == null || userPhone.isEmpty) {
        userPhone = prefs.getString('no_hp');
      }

      if (userPhone == null || userPhone.isEmpty) {
        print("No user phone found for background Pusher");
        return;
      }

      _currentUserPhone = userPhone;
      _currentChannel = _generateParentChannel(userPhone);

      // Initialize Pusher instance untuk background
      _backgroundPusher = PusherChannelsFlutter.getInstance();

      await _backgroundPusher!.init(
        apiKey: "25cc7e774ad55240b5f8", // Ganti dengan key Pusher Anda
        cluster: "ap1",
        onConnectionStateChange: _onBackgroundConnectionStateChange,
        onError: _onBackgroundError,
        onSubscriptionSucceeded: _onBackgroundSubscriptionSucceeded,
        onEvent: _onBackgroundEvent,
      );

      await _backgroundPusher!.connect();
      print("Background Pusher initialized for phone: $userPhone");

    } catch (e) {
      print("Error initializing background Pusher: $e");
    }
  }

  static String _generateParentChannel(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return 'parent-$cleanPhone';
  }

  static void _onBackgroundConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("Background Pusher Connection: $previousState -> $currentState");
    
    if (currentState == 'CONNECTED' && _currentChannel != null) {
      // Subscribe ke channel setelah connected
      Future.delayed(const Duration(seconds: 2), () {
        _backgroundPusher?.subscribe(channelName: _currentChannel!);
      });
    }
  }

  static void _onBackgroundError(String message, int? code, dynamic e) {
    print("Background Pusher Error: $message (Code: $code)");
  }

  static void _onBackgroundSubscriptionSucceeded(String channelName, dynamic data) {
    print("Background Pusher subscribed to: $channelName");
  }

  static void _onBackgroundEvent(PusherEvent event) {
    print("Background Pusher event: ${event.eventName} on ${event.channelName}");
    
    // Handle events di background
    switch (event.eventName) {
      case "absen-masuk":
        _handleBackgroundAbsensiMasuk(event.data);
        break;
        
      case "absen-pulang":
        _handleBackgroundAbsensiPulang(event.data);
        break;
        
      case "parent-notification":
        _handleBackgroundParentNotification(event.data);
        break;
        
      case "test-event":
        _handleBackgroundTestEvent(event.data);
        break;
    }
  }

  static void _handleBackgroundAbsensiMasuk(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String namaAnak = notificationData['nama'] ?? 'Siswa';
      String kelas = notificationData['kelas'] ?? '';
      String waktu = _formatWaktu(notificationData['waktu'] ?? '');
      String status = notificationData['status'] ?? 'Hadir';
      
      String title = "Absensi Masuk";
      String message = "$namaAnak ($kelas) telah masuk sekolah pada $waktu dengan status $status";

      _showBackgroundNotification(title, message, notificationData, 'masuk');
      
    } catch (e) {
      print("Error handling background absensi masuk: $e");
    }
  }

  static void _handleBackgroundAbsensiPulang(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String namaAnak = notificationData['nama'] ?? 'Siswa';
      String kelas = notificationData['kelas'] ?? '';
      String waktuPulang = _formatWaktu(notificationData['waktu_pulang'] ?? '');
      
      String title = "Absensi Pulang";
      String message = "$namaAnak ($kelas) telah pulang sekolah pada $waktuPulang";

      _showBackgroundNotification(title, message, notificationData, 'pulang');
      
    } catch (e) {
      print("Error handling background absensi pulang: $e");
    }
  }

  static void _handleBackgroundParentNotification(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String message = notificationData['message'] ?? '';
      String title = "Notifikasi Orang Tua";

      _showBackgroundNotification(title, message, notificationData, 'parent');
      
    } catch (e) {
      print("Error handling background parent notification: $e");
    }
  }

  static void _handleBackgroundTestEvent(String data) {
    try {
      final Map<String, dynamic> testData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String title = "Test Notification";
      String message = "Background test: ${testData['message'] ?? 'Test berhasil'}";

      _showBackgroundNotification(title, message, testData, 'test');
      
    } catch (e) {
      print("Error handling background test event: $e");
    }
  }

  static String _formatWaktu(String waktu) {
    if (waktu.isEmpty) return '-';
    
    try {
      DateTime dateTime = DateTime.parse(waktu);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      if (waktu.length >= 5) {
        return waktu.substring(0, 5);
      }
      return waktu;
    }
  }

  static Future<void> _showBackgroundNotification(
    String title,
    String body,
    Map<String, dynamic> data,
    String type,
  ) async {
    
    String channelId = 'absensi_background_$type';
    String channelName = 'Background Absensi ${type.toUpperCase()}';
    
    Color notificationColor;
    switch (type) {
      case 'masuk':
        notificationColor = const Color(0xFF4CAF50);
        break;
      case 'pulang':
        notificationColor = const Color(0xFF2196F3);
        break;
      case 'test':
        notificationColor = const Color(0xFFFF9800);
        break;
      default:
        notificationColor = const Color(0xFF9C27B0);
    }

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Background notifications untuk $type sekolah',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      color: notificationColor,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
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

    // Add additional data
    Map<String, dynamic> fullData = {
      ...data,
      'type': 'background_$type',
      'source': 'background_service',
      'timestamp': DateTime.now().toIso8601String(),
    };

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: json.encode(fullData),
    );

    print("Background notification shown: $title");
  }

  static Future<void> _initializeLocalNotifications() async {
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

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> _updatePusherChannel(String newUserPhone) async {
    try {
      // Unsubscribe dari channel lama
      if (_currentChannel != null && _backgroundPusher != null) {
        await _backgroundPusher!.unsubscribe(channelName: _currentChannel!);
        print("Unsubscribed from old channel: $_currentChannel");
      }

      // Update ke channel baru
      _currentUserPhone = newUserPhone;
      _currentChannel = _generateParentChannel(newUserPhone);

      // Save ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_user_phone', newUserPhone);

      // Subscribe ke channel baru
      if (_backgroundPusher != null) {
        await _backgroundPusher!.subscribe(channelName: _currentChannel!);
        print("Subscribed to new channel: $_currentChannel");
      }

    } catch (e) {
      print("Error updating Pusher channel: $e");
    }
  }

  static Future<void> _checkPusherConnection() async {
    try {
      if (_backgroundPusher == null) {
        print("Background Pusher not initialized, reinitializing...");
        await _initializePusherInBackground();
        return;
      }

      // Check connection state
      String connectionState = _backgroundPusher!.connectionState;
      print("Background Pusher connection state: $connectionState");

      if (connectionState != 'CONNECTED') {
        print("Background Pusher not connected, attempting reconnect...");
        await _backgroundPusher!.connect();
      }

    } catch (e) {
      print("Error checking Pusher connection: $e");
    }
  }

  static Future<void> _disconnectPusher() async {
    try {
      if (_backgroundPusher != null) {
        await _backgroundPusher!.disconnect();
        print("Background Pusher disconnected");
      }
    } catch (e) {
      print("Error disconnecting background Pusher: $e");
    }
  }

  // Public methods untuk control dari main app
  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  static Future<void> updateUserPhone(String userPhone) async {
    final service = FlutterBackgroundService();
    service.invoke("updateUserPhone", {
      "userPhone": userPhone,
    });
  }
}

// WorkManager callback untuk maintenance tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "checkAndReconnectPusher":
        await BackgroundPusherService._checkPusherConnection();
        break;
    }
    return Future.value(true);
  });
}