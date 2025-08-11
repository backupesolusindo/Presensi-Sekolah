import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Optional: Hides the debug banner
      title: 'Absensi SMPN 1 Jember',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(), // Set LoginPage as the initial page
      // home: DashboardPage(nama_wali: 'Wali Murid', nis_anak: '12345678'),
    );
  }
}
