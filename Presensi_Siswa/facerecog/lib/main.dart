import 'package:flutter/material.dart';
import 'register_face_page.dart';
import 'face_attendance_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyAppLoader()); // Menampilkan layar loading terlebih dahulu

  var logger = Logger(); // Inisialisasi logger

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        // BAGIAN PENTING
        apiKey: 'AIzaSyDLPEYoVa9zDTnSYo2fJwjJ7rKzHZTSCKk',
        appId: '1:31816478123:android:4687b2935f7abe4a32f6ee',
        messagingSenderId: '31816478123',
        projectId: 'facerecog-4de3d',
        databaseURL: 'https://facerecog-4de3d-default-rtdb.asia-southeast1.firebasedatabase.app',
        storageBucket: 'facerecog-4de3d.appspot.com',
      ),
    );
    runApp(MyApp());
  } catch (e) {
    logger
        .e("Failed to initialize Firebase: ${e.toString()}"); // Gunakan logger
    runApp(MyAppNotConnected(errorMessage: e.toString()));
  }
}

class MyAppLoader extends StatelessWidget {
  const MyAppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Lottie.asset(
            'assets/loading.json', // Path to your Lottie JSON file
            width: 200,
            height: 200,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {
        '/register-face': (context) => RegisterFacePage(),
        '/face-attendance': (context) =>
            FaceAttendancePage(), // Tambahkan rute absensi
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Recognition App'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register-face');
              },
              child: Text('Register Face'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, '/face-attendance'); // Navigasi ke halaman absensi
              },
              child: Text('Face Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
class MyAppNotConnected extends StatelessWidget {
  final String errorMessage;

  const MyAppNotConnected({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Connection Error'),
        ),
        body: Center(
          child: Text('Failed to initialize Firebase: $errorMessage'),
        ),
      ),
    );
  }
}

