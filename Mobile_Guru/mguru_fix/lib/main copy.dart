import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/login_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Welcome/welcome_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMPN 3 JEMBER',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Gunakan initialRoute dan routes untuk navigasi yang lebih baik
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late FirebaseMessaging fm;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notifications
    await _initializeNotifications();
    
    // Get Firebase token
    await _getToken();
    
    // Check login status after delay
    await _getMockLocation();
  }

  Future<void> _initializeNotifications() async {
    try {
      var initializationSettingsAndroid =
          const AndroidInitializationSettings('@mipmap/ic_launcher');
      var initializationSetting =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSetting);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: 'launch_background',
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future<void> _getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        print("Firebase Token: $token");
      } else {
        print("Firebase Token null, tidak disimpan");
      }
    } catch (e) {
      print("Error getting Firebase token: $e");
    }
  }

  Future<void> _getMockLocation() async {
    // Delay untuk splash screen effect
    await Future.delayed(const Duration(seconds: 2));
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      print("Checking login status...");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Initialize status_login if null
      if (prefs.getBool("status_login") == null) {
        await prefs.setBool("status_login", false);
      }
      
      bool isLoggedIn = prefs.getBool("status_login") ?? false;
      
      if (isLoggedIn) {
        // Verify that essential data exists
        String? uuid = prefs.getString("ID");
        String? nama = prefs.getString("Nama");
        String? nip = prefs.getString("NIP");
        
        if (uuid != null && uuid.isNotEmpty && 
            nama != null && nama.isNotEmpty && 
            nip != null && nip.isNotEmpty) {
          print("Status Login: Logged in");
          print("User: $nama");
          print("UUID: $uuid");
          
          // Navigate to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Data incomplete, reset login status
          print("Login data incomplete, resetting...");
          await prefs.setBool("status_login", false);
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        print("Status Login: Not logged in");
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print("Error checking login status: $e");
      // On error, go to login screen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ubah background menjadi putih
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1), // Background logo dengan warna primer transparan
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2), // Shadow lebih lembut
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                "assets/images/logosmpn3.png",
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 30),
            
            // App title
            Text(
              "SMPN 3 JEMBER",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor, // Gunakan warna primer untuk teks
              ),
            ),
            const SizedBox(height: 10),
            
            Text(
              "Sistem Presensi Digital",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600], // Teks dengan warna abu-abu
              ),
            ),
            const SizedBox(height: 40),
            
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor), // Loading indicator dengan warna primer
            ),
            const SizedBox(height: 20),
            
            Text(
              "Memuat aplikasi...",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500], // Teks loading dengan warna abu-abu
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFakeGPSDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: const Text("FAKE GPS TERDETEKSI"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Aplikasi mendeteksi penggunaan Fake GPS."),
                  SizedBox(height: 10),
                  Text("Harap uninstall aplikasi Fake GPS untuk melanjutkan."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Keluar Aplikasi'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // You can add exit app functionality here if needed
                },
              ),
            ],
          ),
        );
      },
    );
  }
}