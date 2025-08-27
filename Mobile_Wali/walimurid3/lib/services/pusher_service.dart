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
  
  // Menyimpan informasi user yang sedang login
  String? _currentUserPhone;
  String? _currentParentChannel;
  final List<String> _subscribedChannels = [];

  Future<void> initialize({
    required String userPhone, // Nomor telepon user yang login (dari data wali/ortu)
    Function(Map<String, dynamic>)? onNotificationTap,
  }) async {
    onNotificationTapCallback = onNotificationTap;
    
    // Simpan informasi user
    _currentUserPhone = userPhone;
    _currentParentChannel = _generateParentChannel(userPhone);
    
    print("🚀 Initializing PusherService for phone: $userPhone");
    print("🚀 Parent channel: $_currentParentChannel");
    
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

    // Subscribe ke channel khusus parent berdasarkan nomor telepon
    if (_currentParentChannel != null) {
      await _subscribeToChannel(_currentParentChannel!);
      print("✅ Subscribed to parent channel: $_currentParentChannel");
    }
    
    // OPTIONAL: Subscribe ke channel umum admin jika diperlukan (untuk testing/monitoring)
    // await _subscribeToChannel("absensi-channel");
  }

  // Helper function untuk generate parent channel name (sama seperti backend)
  String _generateParentChannel(String phoneNumber) {
    // Bersihkan nomor telepon (hilangkan semua karakter non-digit)
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return 'parent-$cleanPhone';
  }

  // Helper function untuk subscribe ke channel dan track subscription
  Future<void> _subscribeToChannel(String channelName) async {
    try {
      await pusher.subscribe(channelName: channelName);
      if (!_subscribedChannels.contains(channelName)) {
        _subscribedChannels.add(channelName);
      }
      print("📡 Subscribed to channel: $channelName");
    } catch (e) {
      print("❌ Failed to subscribe to $channelName: $e");
    }
  }

  // Helper function untuk unsubscribe dari channel
  Future<void> _unsubscribeFromChannel(String channelName) async {
    try {
      await pusher.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
      print("📡 Unsubscribed from channel: $channelName");
    } catch (e) {
      print("❌ Failed to unsubscribe from $channelName: $e");
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
    print("🔄 Pusher Connection: $previousState -> $currentState");
    
    // Jika reconnected, subscribe ulang ke channels
    if (currentState == 'CONNECTED' && _currentParentChannel != null) {
      Future.delayed(const Duration(seconds: 1), () {
        _subscribeToChannel(_currentParentChannel!);
      });
    }
  }

  void onError(String message, int? code, dynamic e) {
    print("❌ Pusher Error: $message (Code: $code)");
    print("❌ Error details: $e");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("✅ Successfully subscribed to: $channelName");
    print("📊 Channel data: $data");
  }

  void onEvent(PusherEvent event) {
    print("📨 Event received: ${event.eventName} on ${event.channelName}");
    print("📨 Event data: ${event.data}");
    
    // Validasi channel - pastikan event dari channel yang benar
    if (!_subscribedChannels.contains(event.channelName)) {
      print("🚫 Event from unsubscribed channel '${event.channelName}' IGNORED");
      return;
    }
    
    // Handle event berdasarkan nama event
    switch (event.eventName) {
      case "absen-masuk":
        print("📝 Processing absen-masuk event");
        _handleAbsensiMasuk(event.data);
        break;
        
      case "absen-pulang":
        print("📝 Processing absen-pulang event");
        _handleAbsensiPulang(event.data);
        break;
        
      case "parent-notification":
        print("👨‍👩‍👧‍👦 Processing parent-notification event");
        _handleParentNotification(event.data);
        break;
        
      case "test-event":
        print("🧪 Processing test event");
        _handleTestEvent(event.data);
        break;
        
      default:
        print("🚫 Unknown event '${event.eventName}' IGNORED");
        return;
    }
  }

  void _handleAbsensiMasuk(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      // Validasi data wajib
      if (!_isValidAbsensiData(notificationData)) {
        print("❌ Invalid absensi-masuk data: missing required fields");
        return;
      }
      
      String namaAnak = notificationData['nama'] ?? 'Siswa';
      String nisAnak = notificationData['nis'] ?? '';
      String waktu = _formatWaktu(notificationData['waktu'] ?? '');
      String kelas = notificationData['kelas'] ?? '';
      String status = notificationData['status'] ?? 'Hadir';
      
      String title = "✅ Absensi Masuk";
      String message = "$namaAnak ($kelas) telah masuk sekolah pada $waktu dengan status $status";

      Map<String, dynamic> extraData = {
        'type': 'absensi_masuk',
        'nis_anak': nisAnak,
        'nama_anak': namaAnak,
        'waktu': waktu,
        'kelas': kelas,
        'status': status,
        'redirect': 'dashboard',
        'full_data': notificationData
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
      if (!_isValidAbsensiData(notificationData)) {
        print("❌ Invalid absensi-pulang data: missing required fields");
        return;
      }
      
      String namaAnak = notificationData['nama'] ?? 'Siswa';
      String nisAnak = notificationData['nis'] ?? '';
      String waktuPulang = _formatWaktu(notificationData['waktu_pulang'] ?? '');
      String kelas = notificationData['kelas'] ?? '';
      
      String title = "🏠 Absensi Pulang";
      String message = "$namaAnak ($kelas) telah pulang sekolah pada $waktuPulang";

      Map<String, dynamic> extraData = {
        'type': 'absensi_pulang',
        'nis_anak': nisAnak,
        'nama_anak': namaAnak,
        'waktu': waktuPulang,
        'kelas': kelas,
        'status': 'pulang',
        'redirect': 'dashboard',
        'full_data': notificationData
      };

      print("✅ Showing absensi pulang notification for: $namaAnak");
      _showLocalNotification(title, message, extraData, 'pulang');
    } catch (e) {
      print("❌ Error parsing absensi pulang notification: $e");
    }
  }

  void _handleParentNotification(String data) {
    try {
      final Map<String, dynamic> notificationData = 
          Map<String, dynamic>.from(json.decode(data));
      
      // Validasi data parent notification
      if (!notificationData.containsKey('message') || 
          !notificationData.containsKey('student_info')) {
        print("❌ Invalid parent-notification data");
        return;
      }

      String message = notificationData['message'] ?? '';
      Map<String, dynamic> studentInfo = notificationData['student_info'] ?? {};
      String namaAnak = studentInfo['nama'] ?? 'Siswa';
      String type = notificationData['type'] ?? 'info';
      
      String title = type == 'masuk' ? "📚 Anak Masuk Sekolah" : "🏠 Anak Pulang Sekolah";

      Map<String, dynamic> extraData = {
        'type': 'parent_notification',
        'message': message,
        'student_info': studentInfo,
        'notification_type': type,
        'redirect': 'dashboard',
        'full_data': notificationData
      };

      print("👨‍👩‍👧‍👦 Showing parent notification for: $namaAnak");
      _showLocalNotification(title, message, extraData, type);
    } catch (e) {
      print("❌ Error parsing parent notification: $e");
    }
  }

  void _handleTestEvent(String data) {
    try {
      final Map<String, dynamic> testData = 
          Map<String, dynamic>.from(json.decode(data));
      
      String title = "🧪 Test Notification";
      String message = "Test data: ${testData['nama']} - ${testData['type']}";
      
      Map<String, dynamic> extraData = {
        'type': 'test',
        'redirect': 'dashboard',
        'test_data': testData
      };

      print("🧪 Showing test notification");
      _showLocalNotification(title, message, extraData, 'test');
    } catch (e) {
      print("❌ Error parsing test event: $e");
    }
  }

  // Helper function untuk validasi data absensi
  bool _isValidAbsensiData(Map<String, dynamic> data) {
    return data.containsKey('nama') && 
           data.containsKey('nis') &&
           data['nama'].toString().isNotEmpty &&
           data['nis'].toString().isNotEmpty;
  }

  // Helper function untuk format waktu
  String _formatWaktu(String waktu) {
    if (waktu.isEmpty) return '-';
    
    try {
      DateTime dateTime = DateTime.parse(waktu);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      // Jika parsing gagal, coba ambil jam:menit saja
      if (waktu.length >= 5) {
        return waktu.substring(0, 5);
      }
      return waktu;
    }
  }

  Future<void> _showLocalNotification(
    String title, 
    String body, 
    Map<String, dynamic> data,
    String type
  ) async {
    
    // Different notification channels untuk berbagai jenis notifikasi
    String channelId = 'absensi_$type';
    String channelName = 'Notifikasi Absensi ${type.toUpperCase()}';
    String channelDescription = 'Notifikasi untuk $type sekolah';

    // Warna dan prioritas berbeda untuk setiap jenis
    Color notificationColor;
    Importance importance;
    
    switch (type) {
      case 'masuk':
        notificationColor = const Color(0xFF4CAF50); // Hijau
        importance = Importance.high;
        break;
      case 'pulang':
        notificationColor = const Color(0xFF2196F3); // Biru
        importance = Importance.high;
        break;
      case 'test':
        notificationColor = const Color(0xFFFF9800); // Orange
        importance = Importance.defaultImportance;
        break;
      default:
        notificationColor = const Color(0xFF9C27B0); // Purple
        importance = Importance.high;
    }

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      color: notificationColor,
      icon: '@mipmap/ic_launcher',
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

    // ID unik untuk setiap notifikasi
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: json.encode(data),
    );

    print("🔔 Notification shown with ID: $notificationId");
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = json.decode(response.payload!);
        print("🎯 Notification tapped with data: $data");
        
        // Call the callback function if provided
        if (onNotificationTapCallback != null) {
          onNotificationTapCallback!(data);
        }
      } catch (e) {
        print("❌ Error parsing notification payload: $e");
      }
    }
  }

  // Method untuk update user phone (ketika user ganti atau login ulang)
  Future<void> updateUserPhone(String newUserPhone) async {
    print("🔄 Updating user phone from $_currentUserPhone to $newUserPhone");
    
    // Unsubscribe dari channel lama
    if (_currentParentChannel != null) {
      await _unsubscribeFromChannel(_currentParentChannel!);
    }
    
    // Update informasi user
    _currentUserPhone = newUserPhone;
    _currentParentChannel = _generateParentChannel(newUserPhone);
    
    // Subscribe ke channel baru
    await _subscribeToChannel(_currentParentChannel!);
    
    print("✅ Updated to new parent channel: $_currentParentChannel");
  }

  // Method untuk subscribe ke channel baru (misalnya setelah login)
  Future<void> subscribeToUserChannel(String userPhone) async {
    await updateUserPhone(userPhone);
  }

  // Method untuk unsubscribe dari channel tertentu
  Future<void> unsubscribeFromUserChannel(String userPhone) async {
    String channelToUnsubscribe = _generateParentChannel(userPhone);
    await _unsubscribeFromChannel(channelToUnsubscribe);
  }

  // Method untuk disconnect dari Pusher dan cleanup
  Future<void> disconnect() async {
    print("🔌 Disconnecting from Pusher...");
    
    // Unsubscribe dari semua channels
    for (String channel in List.from(_subscribedChannels)) {
      await _unsubscribeFromChannel(channel);
    }
    
    await pusher.disconnect();
    
    // Reset state
    _currentUserPhone = null;
    _currentParentChannel = null;
    _subscribedChannels.clear();
    
    print("✅ Disconnected from Pusher");
  }

  // Method untuk reconnect
  Future<void> reconnect() async {
    print("🔄 Reconnecting to Pusher...");
    await pusher.connect();
    
    // Subscribe ulang ke channel yang diperlukan
    if (_currentParentChannel != null) {
      await _subscribeToChannel(_currentParentChannel!);
    }
  }

  // Method untuk cek status koneksi
  bool get isConnected => pusher.connectionState == 'CONNECTED';

  // Getter untuk debugging
  String? get currentUserPhone => _currentUserPhone;
  String? get currentParentChannel => _currentParentChannel;
  List<String> get subscribedChannels => List.from(_subscribedChannels);

  // Method untuk testing - subscribe ke channel tertentu
  Future<void> testSubscribeToChannel(String channelName) async {
    await _subscribeToChannel(channelName);
  }

  // Method untuk logging/debugging info
  void logCurrentState() {
    print("=== PUSHER SERVICE STATE ===");
    print("Connected: $isConnected");
    print("User Phone: $_currentUserPhone");
    print("Parent Channel: $_currentParentChannel");
    print("Subscribed Channels: $_subscribedChannels");
    print("==========================");
  }
}