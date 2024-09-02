import 'package:flutter/material.dart';
import 'camera_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Contoh userId yang bisa diambil dari proses login atau database
    final String userId = 'exampleUserId';  // Ganti dengan ID pengguna yang sebenarnya

    return MaterialApp(
      title: 'Face Recognition Attendance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraPage(userId: userId),
    );
  }
}
