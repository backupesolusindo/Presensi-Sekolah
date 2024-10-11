import 'package:flutter/material.dart';
import 'home.dart';      // Import home page
import 'riwayat.dart';  // Import riwayat page
import 'profile.dart';  // Import profile page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => HomePage(),         // Home page as the initial page
        '/home': (context) => HomePage(),     // Define home route
        '/history': (context) => RiwayatPage(), // Define history route
        '/profile': (context) => ProfilePage(), // Define profile route
      },
    );
  }
}
