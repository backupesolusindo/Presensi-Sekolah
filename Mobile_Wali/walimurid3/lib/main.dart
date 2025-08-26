import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Import the LoginPage
import 'home.dart'; // Import HomePage
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
  bool _isCheckingLogin = true;
  bool _isLoggedIn = false;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    // Cek status login saat app start
    _checkLoginAndInitializePusher();
  }

  Future<void> _checkLoginAndInitializePusher() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? namaWali = prefs.getString('nama_wali');
      String? noHp = prefs.getString('no_hp');
      bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (namaWali != null && noHp != null && isLoggedIn && noHp.isNotEmpty) {
        // User sudah login, initialize Pusher dengan nomor telepon
        print("User already logged in with phone: $noHp");
        
        await _initializePusherWithPhone(noHp);
        
        setState(() {
          _isLoggedIn = true;
          _userPhone = noHp;
          _isCheckingLogin = false;
        });
      } else {
        // User belum login atau data tidak lengkap
        print("User not logged in or incomplete data");
        setState(() {
          _isLoggedIn = false;
          _isCheckingLogin = false;
        });
      }
    } catch (e) {
      print("Error checking login status: $e");
      setState(() {
        _isLoggedIn = false;
        _isCheckingLogin = false;
      });
    }
  }

  Future<void> _initializePusherWithPhone(String userPhone) async {
    try {
      await PusherService().initialize(
        userPhone: userPhone, // Gunakan userPhone, bukan userId
        onNotificationTap: _handleNotificationTap,
      );
      print("✅ Pusher initialized successfully for phone: $userPhone");
    } catch (e) {
      print("❌ Failed to initialize Pusher: $e");
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle notification tap di sini
    print("🎯 Notification tapped: $data");
    
    // Ambil informasi dari data notifikasi
    String type = data['type'] ?? '';
    String redirect = data['redirect'] ?? 'dashboard';
    String namaAnak = data['nama_anak'] ?? '';
    String nisAnak = data['nis_anak'] ?? '';
    
    // Log untuk debugging
    print("Notification type: $type");
    print("Redirect to: $redirect");
    print("Student: $namaAnak ($nisAnak)");
    
    // Navigate berdasarkan redirect atau type
    switch (type) {
      case 'absensi_masuk':
      case 'absensi_pulang':
      case 'parent_notification':
        // Navigate ke halaman dashboard/absensi
        _navigateToPage(redirect);
        break;
      case 'pengumuman':
        // Navigate ke halaman pengumuman
        _navigateToPage('pengumuman');
        break;
      case 'test':
        // Handle test notification
        print("Test notification received");
        break;
      default:
        // Default navigate ke dashboard
        _navigateToPage('dashboard');
        break;
    }
  }

  void _navigateToPage(String page) {
    // Implementasi navigasi berdasarkan halaman
    // Sesuaikan dengan routing aplikasi Anda
    switch (page) {
      case 'dashboard':
      case 'home':
        // Navigate ke HomePage jika sudah login
        if (_isLoggedIn) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
        break;
      case 'absensi':
        // Navigate ke halaman absensi
        print("Navigate to absensi page");
        break;
      case 'pengumuman':
        // Navigate ke halaman pengumuman
        print("Navigate to pengumuman page");
        break;
      default:
        print("Unknown page: $page");
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
      home: _buildHomeWidget(),
    );
  }

  Widget _buildHomeWidget() {
    // Tampilkan loading saat mengecek status login
    if (_isCheckingLogin) {
      return _buildLoadingScreen();
    }
    
    // Jika sudah login, langsung ke HomePage
    if (_isLoggedIn) {
      return const HomePage();
    }
    
    // Jika belum login, tampilkan LoginPage
    return const LoginPage();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/walibg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              SizedBox(height: 20),
              Text(
                'Memuat aplikasi...',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Mohon tunggu sebentar',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}