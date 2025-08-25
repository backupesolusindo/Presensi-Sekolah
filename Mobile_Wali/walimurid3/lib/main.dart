import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginPage
import 'services/pusher_service.dart'; // Import Pusher Service

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Pusher service saat app start
    _initializePusher();
  }

  Future<void> _initializePusher() async {
    // Initialize tanpa user ID dulu, nanti subscribe setelah login
    try {
      await PusherService().initialize(
        userId: "guest", // Temporary, akan diganti setelah login
        onNotificationTap: _handleNotificationTap,
      );
      print("Pusher service initialized");
    } catch (e) {
      print("Failed to initialize Pusher: $e");
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle notification tap di sini
    print("Notification tapped: $data");
    
    // Contoh: Navigate ke screen tertentu berdasarkan type
    String type = data['type'] ?? '';
    String redirect = data['redirect'] ?? 'dashboard';
    
    switch (type) {
      case 'absensi':
        // Navigate ke halaman absensi atau dashboard
        print("Navigate to absensi page");
        break;
      case 'pengumuman':
        // Navigate ke halaman pengumuman
        print("Navigate to pengumuman page");
        break;
      default:
        // Navigate ke dashboard
        print("Navigate to dashboard");
        break;
    }
  }

  @override
  void dispose() {
    // Disconnect Pusher saat app ditutup
    PusherService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi SMPN 1 Jember',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
      // home: DashboardPage(nama_wali: 'Wali Murid', nis_anak: '12345678'),
    );
  }
}