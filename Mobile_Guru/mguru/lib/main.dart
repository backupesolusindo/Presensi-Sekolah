import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the LoginPage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Optional: Hides the debug banner
      title: 'Absensi SMPN 1 Jember',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(), // Set LoginPage as the initial page
    );
  }
}
