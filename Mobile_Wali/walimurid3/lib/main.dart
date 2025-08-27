import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Import the LoginPage
import 'home.dart'; // Import HomePage
import 'services/pusher_service.dart'; // Import Pusher Service
// Import Background Service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service untuk Pusher
  //await BackgroundPusherService.initializeService();
  
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
    _checkLoginAndInitializeServices();
  }

  Future<void> _checkLoginAndInitializeServices() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? namaWali = prefs.getString('nama_wali');
      String? noHp = prefs.getString('no_hp');
      bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (namaWali != null && noHp != null && isLoggedIn && noHp.isNotEmpty) {
        // User sudah login
        print("User already logged in with phone: $noHp");
        
        // Initialize Pusher Service untuk foreground
        await _initializePusherService(noHp);
        
        // Start background service
        //await _startBackgroundService(noHp);
        
        setState(() {
          _isLoggedIn = true;
          _userPhone = noHp;
          _isCheckingLogin = false;
        });
      } else {
        // User belum login
        print("User not logged in");
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

  Future<void> _initializePusherService(String userPhone) async {
    try {
      await PusherService().initialize(
        userPhone: userPhone,
        onNotificationTap: _handleNotificationTap,
      );
      print("Foreground Pusher Service initialized for phone: $userPhone");
    } catch (e) {
      print("Failed to initialize Pusher Service: $e");
    }
  }

  // Future<void> _startBackgroundService(String userPhone) async {
  //   try {
  //     // Start background service
  //     await BackgroundPusherService.startService();
      
  //     // Update user phone untuk background service
  //     await BackgroundPusherService.updateUserPhone(userPhone);
      
  //     print("Background Pusher Service started for phone: $userPhone");
  //   } catch (e) {
  //     print("Failed to start Background Service: $e");
  //   }
  // }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle notification tap
    print("Notification tapped: $data");
    
    String type = data['type'] ?? '';
    String redirect = data['redirect'] ?? 'dashboard';
    String namaAnak = data['nama_anak'] ?? '';
    String nisAnak = data['nis_anak'] ?? '';
    
    print("Notification type: $type");
    print("Redirect to: $redirect");
    print("Student: $namaAnak ($nisAnak)");
    
    // Navigate berdasarkan type
    switch (type) {
      case 'absensi_masuk':
      case 'absensi_pulang':
      case 'parent_notification':
      case 'background_masuk':
      case 'background_pulang':
        _navigateToPage(redirect);
        break;
      case 'pengumuman':
        _navigateToPage('pengumuman');
        break;
      case 'test':
      case 'background_test':
        print("Test notification received");
        _navigateToPage('dashboard');
        break;
      default:
        _navigateToPage('dashboard');
        break;
    }
  }

  void _navigateToPage(String page) {
    switch (page) {
      case 'dashboard':
      case 'home':
        if (_isLoggedIn) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
        break;
      case 'absensi':
        print("Navigate to absensi page");
        break;
      case 'pengumuman':
        print("Navigate to pengumuman page");
        break;
      default:
        print("Unknown page: $page");
        break;
    }
  }

  @override
  void dispose() {
    // Disconnect foreground services saat app ditutup
    // Background service akan tetap berjalan
    try {
      PusherService().disconnect();
    } catch (e) {
      print("Error disposing services: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Presensi SMPN 3 Jember',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _buildHomeWidget(),
    );
  }

  Widget _buildHomeWidget() {
    if (_isCheckingLogin) {
      return _buildLoadingScreen();
    }
    
    if (_isLoggedIn) {
      return const HomePage();
    }
    
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
                'Mengaktifkan layanan notifikasi...',
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