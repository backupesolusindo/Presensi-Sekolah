import 'dart:convert';
import 'dart:typed_data';
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
      apiKey: "25cc7e774ad55240b5f8", // Ganti dengan key dari dashboard Pusher
      cluster: "ap1", // Ganti dengan cluster Anda
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
    // DISESUAIKAN DENGAN KODE BACKEND
    await pusher.subscribe(channelName: "absensi-channel");
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
    
    // STRICT filtering - hanya proses event yang benar-benar diinginkan
    // DISESUAIKAN DENGAN NAMA EVENT BACKEND
    if (event.eventName == "absen-masuk") {
      print("Processing absen-masuk event");
      _handleAbsensiMasuk(event.data);
    } else if (event.eventName == "absen-pulang") {
      print("Processing absen-pulang event");
      _handleAbsensiPulang(event.data);
    } else {
      // Log event yang diabaikan
      print("🚫 Event '${event.eventName}' IGNORED - only handling 'absen-masuk' and 'absen-pulang'");
      return; // Langsung return, tidak proses apapun
    }
  }

  void _handleAbsensiMasuk(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      // Validasi data wajib
      if (!notificationData.containsKey('nama') || 
          !notificationData.containsKey('nis')) {
        print("❌ Invalid absensi-masuk data: missing required fields");
        return;
      }
      
      String namaAnak = notificationData['nama'] ?? 'Siswa';
      String nisAnak = notificationData['nis'] ?? '';
      String waktu = notificationData['waktu'] ?? '';
      String kelas = notificationData['kelas'] ?? '';
      
      // Jangan tampilkan jika data kosong/invalid
      if (namaAnak.isEmpty || nisAnak.isEmpty) {
        print("❌ Absensi masuk data incomplete - notification skipped");
        return;
      }
      
      String title = "Absensi Masuk";
      String message = "$namaAnak ($kelas) telah masuk sekolah pada $waktu";

      Map<String, dynamic> extraData = {
        'type': 'absensi_masuk',
        'nis_anak': nisAnak,
        'nama_anak': namaAnak,
        'waktu': waktu,
        'kelas': kelas,
        'status': 'masuk',
        'redirect': 'dashboard'
      };

      print("✅ Showing absensi masuk notification for: $namaAnak");
      _showLocalNotification(title, message, extraData, 'masuk');
    } catch (e) {
      print("❌ Error parsing absensi masuk notification: $e");
    }
  }

  void _handleAbsensiPulang(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      // Validasi data wajib
      if (!notificationData.containsKey('nama') || 
          !notificationData.containsKey('nis')) {
        print("❌ Invalid absensi-pulang data: missing required fields");
        return;
      }
      
      String namaAnak = notificationData['nama'] ?? 'Siswa';
      String nisAnak = notificationData['nis'] ?? '';
      String waktu = notificationData['waktu_pulang'] ?? ''; // Menggunakan kunci 'waktu_pulang'
      String kelas = notificationData['kelas'] ?? '';
      
      // Jangan tampilkan jika data kosong/invalid
      if (namaAnak.isEmpty || nisAnak.isEmpty) {
        print("❌ Absensi pulang data incomplete - notification skipped");
        return;
      }
      
      String title = "Absensi Pulang";
      String message = "$namaAnak ($kelas) telah pulang sekolah pada $waktu";

      Map<String, dynamic> extraData = {
        'type': 'absensi_pulang',
        'nis_anak': nisAnak,
        'nama_anak': namaAnak,
        'waktu': waktu,
        'kelas': kelas,
        'status': 'pulang',
        'redirect': 'dashboard'
      };

      print(" Showing absensi pulang notification for: $namaAnak");
      _showLocalNotification(title, message, extraData, 'pulang');
    } catch (e) {
      print("❌ Error parsing absensi pulang notification: $e");
    }
  }

  Future<void> _showLocalNotification(
    String title, 
    String body, 
    Map<String, dynamic> data,
    String type
  ) async {
    
    // Different notification channels untuk masuk dan pulang
    String channelId = 'absensi_$type';
    String channelName = 'Notifikasi Absensi ${type.toUpperCase()}';
    String channelDescription = 'Notifikasi untuk absensi $type sekolah';

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      // Styling berbeda untuk masuk dan pulang
      color: type == 'masuk' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3), // Hijau untuk masuk, biru untuk pulang
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

  // Method untuk cek status koneksi
  bool get isConnected => pusher.connectionState == 'CONNECTED';
}