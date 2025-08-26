import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:pusher_beams/pusher_beams.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  // ---------- KONFIGURASI ----------
  static const String _pusherChannelsKey = '25cc7e774ad55240b5f8'; // TODO
  static const String _pusherCluster = 'ap1';          // TODO (mis. "ap1")
  static const String _beamsInstanceId = 'd0ab323d-9f13-4d95-bd00-3998a788e5cd'; // TODO

  // ---------- INSTANCES ----------
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Callback ketika user tap notifikasi
  Function(Map<String, dynamic>)? onNotificationTapCallback;

  // state user/channel
  String? _currentUserPhone;
  String? _currentParentChannel; // untuk Channels
  String? _currentParentInterest; // untuk Beams
  final List<String> _subscribedChannels = [];

  // ------------- PUBLIC API -------------

  Future<void> initialize({
    required String userPhone, // nomor HP ortu yg login
    Function(Map<String, dynamic>)? onNotificationTap,
  }) async {
    onNotificationTapCallback = onNotificationTap;

    // simpan state
    _currentUserPhone = userPhone;
    _currentParentChannel = _generateParentChannel(userPhone);   // Channels
    _currentParentInterest = _generateParentInterest(userPhone); // Beams

    // init local notifications (untuk tampilkan notifikasi saat app foreground)
    await _initializeLocalNotifications();

    // init Pusher Beams (PUSH NOTIF —> jalan saat background/terminated)
    await _initializeBeams();

    // init Pusher Channels (REALTIME —> saat app terbuka)
    await _initializeChannels();

    // subscribe realtime channel parent-<phone> (channels)
    if (_currentParentChannel != null) {
      await _subscribeToChannel(_currentParentChannel!);
    }

    // optional: subscribe ke channel umum admin (untuk debugging)
    // await _subscribeToChannel("absensi-channel");
  }

  // update nomor hp (misal setelah ganti akun)
  Future<void> updateUserPhone(String newUserPhone) async {
    // Unsubscribe dari Channels lama
    if (_currentParentChannel != null) {
      await _unsubscribeFromChannel(_currentParentChannel!);
    }

    // Hapus interest Beams lama
    if (_currentParentInterest != null) {
      await PusherBeams.instance.removeDeviceInterest(_currentParentInterest!);
    }

    // set state baru
    _currentUserPhone = newUserPhone;
    _currentParentChannel = _generateParentChannel(newUserPhone);
    _currentParentInterest = _generateParentInterest(newUserPhone);

    // subscribe ulang
    await _subscribeToChannel(_currentParentChannel!);
    if (_currentParentInterest != null) {
      await PusherBeams.instance.addDeviceInterest(_currentParentInterest!);
    }
  }

  Future<void> disconnect() async {
    // bersihkan Channels
    for (final ch in List<String>.from(_subscribedChannels)) {
      await _unsubscribeFromChannel(ch);
    }
    await pusher.disconnect();

    // bersihkan Beams (optional—tetap tersubscribe di device jika tidak dihapus)
    if (_currentParentInterest != null) {
      await PusherBeams.instance.removeDeviceInterest(_currentParentInterest!);
    }

    _currentUserPhone = null;
    _currentParentChannel = null;
    _currentParentInterest = null;
    _subscribedChannels.clear();
  }

  Future<void> reconnect() async {
    await pusher.connect();
    if (_currentParentChannel != null) {
      await _subscribeToChannel(_currentParentChannel!);
    }
  }

  bool get isConnected => pusher.connectionState == 'CONNECTED';
  String? get currentUserPhone => _currentUserPhone;
  String? get currentParentChannel => _currentParentChannel;
  List<String> get subscribedChannels => List.unmodifiable(_subscribedChannels);

  // ------------- PRIVATE: INIT --------------

  Future<void> _initializeChannels() async {
    await pusher.init(
      apiKey: _pusherChannelsKey,
      cluster: _pusherCluster,
      onConnectionStateChange: onConnectionStateChange,
      onError: onError,
      onSubscriptionSucceeded: onSubscriptionSucceeded,
      onEvent: onEvent,
    );
    await pusher.connect();
  }

  Future<void> _initializeBeams() async {
    // start Beams
    await PusherBeams.instance.start(_beamsInstanceId);

    // subscribe ke interest umum dan interest parent-<phone>
    await PusherBeams.instance.addDeviceInterest('absensi'); // umum
    if (_currentParentInterest != null) {
      await PusherBeams.instance.addDeviceInterest(_currentParentInterest!);
    }

    // Terima pesan ketika APP FOREGROUND → kita tampilkan memakai local notifications
    await PusherBeams.instance
        .onMessageReceivedInTheForeground(_onBeamsForegroundMessage);

    // Ketika user TAP notifikasi (app background/terminated), plugin akan
    // memberikan payload. Kita teruskan ke callback.
    await PusherBeams.instance.onNotificationOpenedApp((payload) async {
      try {
        // payload.data adalah Map<String, dynamic> (FCM "data" kalau ada)
        final data = <String, dynamic>{};
        if (payload.data != null) {
          data['data'] = payload.data;
        }
        data['source'] = 'beams';
        if (onNotificationTapCallback != null) {
          onNotificationTapCallback!(data);
        }
      } catch (_) {}
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const init = InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(
      init,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 13+ permissions
    final and = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await and?.requestNotificationsPermission();
    await and?.requestExactAlarmsPermission();
  }

  // ------------- HELPERS: NAMA --------------

  String _generateParentChannel(String phone) =>
      'parent-${phone.replaceAll(RegExp(r'[^0-9]'), '')}';

  String _generateParentInterest(String phone) =>
      'parent-${phone.replaceAll(RegExp(r'[^0-9]'), '')}';

  // ------------- CHANNELS (REALTIME) -------------

  Future<void> _subscribeToChannel(String channelName) async {
    try {
      await pusher.subscribe(channelName: channelName);
      if (!_subscribedChannels.contains(channelName)) {
        _subscribedChannels.add(channelName);
      }
    } catch (e) {
      debugPrint("❌ Failed to subscribe $channelName: $e");
    }
  }

  Future<void> _unsubscribeFromChannel(String channelName) async {
    try {
      await pusher.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
    } catch (e) {
      debugPrint("❌ Failed to unsubscribe $channelName: $e");
    }
  }

  // ------------- CHANNELS CALLBACKS -------------

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    debugPrint("🔄 Channels: $previousState -> $currentState");
    if (currentState == 'CONNECTED' && _currentParentChannel != null) {
      Future.delayed(const Duration(milliseconds: 700), () {
        _subscribeToChannel(_currentParentChannel!);
      });
    }
  }

  void onError(String message, int? code, dynamic e) {
    debugPrint("❌ Channels Error: $message ($code) $e");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint("✅ Channels subscribed: $channelName");
  }

  void onEvent(PusherEvent event) {
    debugPrint("📨 Channels event: ${event.eventName} @${event.channelName}");
    if (!_subscribedChannels.contains(event.channelName)) return;

    switch (event.eventName) {
      case "absen-masuk":
        _handleAbsensiMasuk(event.data);
        break;
      case "absen-pulang":
        _handleAbsensiPulang(event.data);
        break;
      case "parent-notification":
        _handleParentNotification(event.data);
        break;
      case "test-event":
        _handleTestEvent(event.data);
        break;
      default:
        break;
    }
  }

  // ------------- BEAMS (FOREGROUND) -------------

  Future<void> _onBeamsForegroundMessage(Map<Object?, Object?> message) async {
    // Struktur payload tergantung kiriman server (FCM/APNs).
    // Kita ambil title/body kalau ada, lalu tampilkan sebagai local notification.
    try {
      final notification = message['notification'] as Map?; // iOS
      final android = message['android'] as Map?; // Android (kadang di sini)
      String? title;
      String? body;
      Map<String, dynamic> data = {};

      if (android != null && android['notification'] is Map) {
        final m = Map<String, dynamic>.from(android['notification']);
        title = m['title']?.toString();
        body = m['body']?.toString();
      } else if (notification != null) {
        final m = Map<String, dynamic>.from(notification as Map);
        title = m['title']?.toString();
        body = m['body']?.toString();
      }

      if (message['data'] is Map) {
        data = Map<String, dynamic>.from(message['data'] as Map);
      }

      // fallback
      title ??= 'Notifikasi';
      body ??= 'Ada notifikasi baru';

      await _showLocalNotification(title, body, {'source': 'beams', ...data}, 'info');
    } catch (e) {
      debugPrint('❌ Beams foreground parse error: $e');
    }
  }

  // ------------- HANDLERS (LOGIKA NOTIF) -------------

  void _handleAbsensiMasuk(String data) {
    try {
      final m = Map<String, dynamic>.from(json.decode(data));
      if (!_isValidAbsensiData(m)) return;

      final nama = m['nama'] ?? 'Siswa';
      final kelas = m['kelas'] ?? '';
      final waktu = _formatWaktu(m['waktu'] ?? '');
      final status = m['status'] ?? 'Hadir';

      _showLocalNotification(
        "✅ Absensi Masuk",
        "$nama ($kelas) masuk pada $waktu, status $status",
        {
          'type': 'absensi_masuk',
          'full_data': m,
        },
        'masuk',
      );
    } catch (e) {
      debugPrint("❌ absensi-masuk parse: $e");
    }
  }

  void _handleAbsensiPulang(String data) {
    try {
      final m = Map<String, dynamic>.from(json.decode(data));
      if (!_isValidAbsensiData(m)) return;

      final nama = m['nama'] ?? 'Siswa';
      final kelas = m['kelas'] ?? '';
      final waktuPulang = _formatWaktu(m['waktu_pulang'] ?? '');

      _showLocalNotification(
        "🏠 Absensi Pulang",
        "$nama ($kelas) pulang pada $waktuPulang",
        {
          'type': 'absensi_pulang',
          'full_data': m,
        },
        'pulang',
      );
    } catch (e) {
      debugPrint("❌ absensi-pulang parse: $e");
    }
  }

  void _handleParentNotification(String data) {
    try {
      final m = Map<String, dynamic>.from(json.decode(data));
      final msg = (m['message'] ?? '').toString();
      final type = (m['type'] ?? 'info').toString();

      _showLocalNotification(
        type == 'masuk' ? "📚 Anak Masuk Sekolah" : "🏠 Anak Pulang Sekolah",
        msg.isEmpty ? 'Notifikasi orang tua' : msg,
        {'type': 'parent', 'full_data': m},
        type,
      );
    } catch (e) {
      debugPrint("❌ parent-notification parse: $e");
    }
  }

  void _handleTestEvent(String data) {
    try {
      final m = Map<String, dynamic>.from(json.decode(data));
      _showLocalNotification(
        "🧪 Test Notification",
        "Test data: ${m['nama']} - ${m['type']}",
        {'type': 'test', 'full_data': m},
        'test',
      );
    } catch (e) {
      debugPrint("❌ test-event parse: $e");
    }
  }

  // ------------- UTIL --------------

  bool _isValidAbsensiData(Map<String, dynamic> m) =>
      m.containsKey('nama') && m.containsKey('nis');

  String _formatWaktu(String waktu) {
    if (waktu.isEmpty) return '-';
    try {
      final dt = DateTime.parse(waktu);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return waktu.length >= 5 ? waktu.substring(0, 5) : waktu;
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
    String type,
  ) async {
    final channelId = 'absensi_$type';
    final channelName = 'Notifikasi Absensi ${type.toUpperCase()}';
    final channelDesc = 'Notifikasi untuk $type sekolah';

    Color color;
    Importance imp;
    switch (type) {
      case 'masuk':
        color = const Color(0xFF4CAF50);
        imp = Importance.high;
        break;
      case 'pulang':
        color = const Color(0xFF2196F3);
        imp = Importance.high;
        break;
      case 'test':
        color = const Color(0xFFFF9800);
        imp = Importance.defaultImportance;
        break;
      default:
        color = const Color(0xFF9C27B0);
        imp = Importance.high;
    }

    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: imp,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 600, 250, 600]),
      color: color,
      icon: '@mipmap/ic_launcher',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(android: android, iOS: ios);
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: json.encode(data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = Map<String, dynamic>.from(json.decode(response.payload!));
      if (onNotificationTapCallback != null) {
        onNotificationTapCallback!(data);
      }
    } catch (e) {
      debugPrint('❌ payload parse: $e');
    }
  }

  // ------- debugging -------
  void logCurrentState() {
    debugPrint("=== PUSHER SERVICE STATE ===");
    debugPrint("Connected (Channels): $isConnected");
    debugPrint("User Phone: $_currentUserPhone");
    debugPrint("Parent Channel (Channels): $_currentParentChannel");
    debugPrint("Parent Interest (Beams): $_currentParentInterest");
    debugPrint("Subscribed Channels: $_subscribedChannels");
    debugPrint("============================");
  }
}