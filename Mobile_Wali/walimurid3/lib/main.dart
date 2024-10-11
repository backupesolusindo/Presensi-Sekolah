import 'package:flutter/material.dart';
import 'home.dart'; // Import the home.dart file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      home: HomePage(), // Set HomePage dari home.dart sebagai halaman utama
      theme: ThemeData(
        primarySwatch: Colors.blue, // Ubah warna tema sesuai kebutuhan
      ),
    );
  }
}
