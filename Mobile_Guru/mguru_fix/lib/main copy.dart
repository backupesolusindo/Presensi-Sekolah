// import 'dart:async';
// import 'dart:ui';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:mobile_presensi_kdtg/Screens/Login/login_screen.dart';
// import 'package:mobile_presensi_kdtg/Screens/Welcome/welcome_screen.dart';
// import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
// import 'package:mobile_presensi_kdtg/constants.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print('Handling a background message ${message.messageId}');
// }

// const AndroidNotificationChannel channel = AndroidNotificationChannel(
//   'high_importance_channel', // id
//   'High Importance Notifications', // title
//   importance: Importance.high,
// );

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   try {
//     await Firebase.initializeApp();
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   } catch (e) {
//     print("Firebase initialization error: $e");
//   }

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'SMPN 3 JEMBER',
//       theme: ThemeData(
//         primaryColor: kPrimaryColor,
//         scaffoldBackgroundColor: Colors.white,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       // Gunakan initialRoute dan routes untuk navigasi yang lebih baik
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const SplashScreen(),
//         '/welcome': (context) => const WelcomeScreen(),
//         '/login': (context) => const LoginScreen(),
//         '/dashboard': (context) => const DashboardScreen(),
//       },
//     );
//   }
// }

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
//   late FirebaseMessaging fm;
//   late AnimationController _fadeController;
//   late AnimationController _scaleController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _startAnimations();
//     _initializeApp();
//   }

//   void _initializeAnimations() {
//     // Fade animation controller
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
    
//     // Scale animation controller
//     _scaleController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
    
//     // Slide animation controller
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );

//     // Fade animation
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     ));

//     // Scale animation
//     _scaleAnimation = Tween<double>(
//       begin: 0.5,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _scaleController,
//       curve: Curves.elasticOut,
//     ));

//     // Slide animation
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));
//   }

//   void _startAnimations() {
//     // Start animations with delays
//     _fadeController.forward();
    
//     Timer(const Duration(milliseconds: 300), () {
//       _scaleController.forward();
//     });
    
//     Timer(const Duration(milliseconds: 600), () {
//       _slideController.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _scaleController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeApp() async {
//     // Initialize notifications
//     await _initializeNotifications();
    
//     // Get Firebase token
//     await _getToken();
    
//     // Check login status after delay
//     await _getMockLocation();
//   }

//   Future<void> _initializeNotifications() async {
//     try {
//       var initializationSettingsAndroid =
//           const AndroidInitializationSettings('@mipmap/ic_launcher');
//       var initializationSetting =
//           InitializationSettings(android: initializationSettingsAndroid);

//       await flutterLocalNotificationsPlugin.initialize(initializationSetting);

//       // Listen for foreground messages
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         RemoteNotification? notification = message.notification;
//         AndroidNotification? android = message.notification?.android;
//         if (notification != null && android != null) {
//           flutterLocalNotificationsPlugin.show(
//             notification.hashCode,
//             notification.title,
//             notification.body,
//             NotificationDetails(
//               android: AndroidNotificationDetails(
//                 channel.id,
//                 channel.name,
//                 icon: 'launch_background',
//               ),
//             ),
//           );
//         }
//       });
//     } catch (e) {
//       print("Error initializing notifications: $e");
//     }
//   }

//   Future<void> _getToken() async {
//     try {
//       String? token = await FirebaseMessaging.instance.getToken();
//       if (token != null) {
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         await prefs.setString("token", token);
//         print("Firebase Token: $token");
//       } else {
//         print("Firebase Token null, tidak disimpan");
//       }
//     } catch (e) {
//       print("Error getting Firebase token: $e");
//     }
//   }

//   Future<void> _getMockLocation() async {
//     // Delay untuk splash screen effect
//     await Future.delayed(const Duration(seconds: 3));
//     _checkLoginStatus();
//   }

//   Future<void> _checkLoginStatus() async {
//     try {
//       print("Checking login status...");
//       SharedPreferences prefs = await SharedPreferences.getInstance();
      
//       // Initialize status_login if null
//       if (prefs.getBool("status_login") == null) {
//         await prefs.setBool("status_login", false);
//       }
      
//       bool isLoggedIn = prefs.getBool("status_login") ?? false;
      
//       if (isLoggedIn) {
//         // Verify that essential data exists
//         String? uuid = prefs.getString("ID");
//         String? nama = prefs.getString("Nama");
//         String? nip = prefs.getString("NIP");
        
//         if (uuid != null && uuid.isNotEmpty && 
//             nama != null && nama.isNotEmpty && 
//             nip != null && nip.isNotEmpty) {
//           print("Status Login: Logged in");
//           print("User: $nama");
//           print("UUID: $uuid");
          
//           // Navigate to dashboard
//           Navigator.pushReplacementNamed(context, '/dashboard');
//         } else {
//           // Data incomplete, reset login status
//           print("Login data incomplete, resetting...");
//           await prefs.setBool("status_login", false);
//           Navigator.pushReplacementNamed(context, '/login');
//         }
//       } else {
//         print("Status Login: Not logged in");
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//     } catch (e) {
//       print("Error checking login status: $e");
//       // On error, go to login screen
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.white,
//               Colors.grey.shade50,
//               Colors.white,
//             ],
//             stops: const [0.0, 0.5, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Logo section with animations
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: ScaleTransition(
//                     scale: _scaleAnimation,
//                     child: Container(
//                       padding: const EdgeInsets.all(30),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(25),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.1),
//                             blurRadius: 20,
//                             spreadRadius: 8,
//                             offset: const Offset(0, 8),
//                           ),
//                           BoxShadow(
//                             color: kPrimaryColor.withOpacity(0.05),
//                             blurRadius: 40,
//                             spreadRadius: 15,
//                             offset: const Offset(0, 12),
//                           ),
//                         ],
//                       ),
//                       child: Image.asset(
//                         "assets/images/logosmpn3.png",
//                         width: 120,
//                         height: 120,
//                       ),
//                     ),
//                   ),
//                 ),
                
//                 const SizedBox(height: 40),
                
//                 // Title section with slide animation
//                 SlideTransition(
//                   position: _slideAnimation,
//                   child: FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: Column(
//                       children: [
//                         // Main title
//                         ShaderMask(
//                           shaderCallback: (bounds) => LinearGradient(
//                             colors: [
//                               Colors.blue.shade700,
//                               Colors.blue.shade500,
//                             ],
//                           ).createShader(bounds),
//                           child: const Text(
//                             "SMPN 3 JEMBER",
//                             style: TextStyle(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                               letterSpacing: 1.2,
//                             ),
//                           ),
//                         ),
                        
//                         const SizedBox(height: 8),
                        
//                         // Subtitle
//                         Text(
//                           "Sistem Presensi Digital",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey.shade600,
//                             fontWeight: FontWeight.w500,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
                        
//                         const SizedBox(height: 6),
                        
//                         // Version or additional info
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             "Smart Attendance System",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.blue.shade700,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
                
//                 const SizedBox(height: 60),
                
//                 // Loading section
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Column(
//                     children: [
//                       // Custom loading indicator
//                       Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           // Outer circle
//                           SizedBox(
//                             width: 60,
//                             height: 60,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 3,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 kPrimaryColor.withOpacity(0.3),
//                               ),
//                             ),
//                           ),
//                           // Inner circle
//                           SizedBox(
//                             width: 45,
//                             height: 45,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 kPrimaryColor,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 24),
                      
//                       // Loading text
//                       Text(
//                         "Memuat aplikasi...",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade500,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Bottom spacing
//                 const SizedBox(height: 80),
                
//                 // Footer info
//                 SlideTransition(
//                   position: _slideAnimation,
//                   child: FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: Column(
//                       children: [
//                         Text(
//                           "Powered by Technology",
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade400,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.security,
//                               size: 14,
//                               color: Colors.grey.shade400,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               "Secure & Reliable",
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.grey.shade400,
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _showFakeGPSDialog() async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
//           child: AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             title: Row(
//               children: [
//                 Icon(
//                   Icons.warning_amber_rounded,
//                   color: Colors.orange.shade600,
//                   size: 28,
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   "FAKE GPS TERDETEKSI",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             content: Container(
//               decoration: BoxDecoration(
//                 color: Colors.orange.shade50,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               padding: const EdgeInsets.all(16),
//               child: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Aplikasi mendeteksi penggunaan Fake GPS.",
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Text(
//                     "Harap uninstall aplikasi Fake GPS untuk melanjutkan menggunakan sistem presensi.",
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 style: TextButton.styleFrom(
//                   backgroundColor: Colors.red.shade50,
//                   foregroundColor: Colors.red.shade700,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 12,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text(
//                   'Keluar Aplikasi',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   // You can add exit app functionality here if needed
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }